#!/bin/bash

# Create separate Docker networks for each cluster
echo "Creating Docker networks..."
docker network create rancher-network --driver bridge --subnet=172.20.0.0/16
docker network create mlflow-network --driver bridge --subnet=172.21.0.0/16

# Create bridge network for inter-cluster communication
docker network create cluster-bridge --driver bridge --subnet=172.22.0.0/16

echo "Docker networks created:"
docker network ls | grep -E "(rancher-network|mlflow-network|cluster-bridge)"

# Create k3d rancher-mgmt cluster on rancher-network
echo "Creating rancher-mgmt cluster..."
k3d cluster create rancher-mgmt \
  --network rancher-network \
  --volume $PWD/.data-rancher-mgmt:/data \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --api-port 6550 \
  --servers 1

# Connect rancher-mgmt cluster to bridge network for inter-cluster communication
docker network connect cluster-bridge k3d-rancher-mgmt-server-0

k3d cluster list

# Switch context to rancher-mgmt
k3d kubeconfig merge rancher-mgmt --kubeconfig-switch-context

# Install cert-manager
echo "Installing cert-manager..."
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager --namespace cert-manager --set installCRDs=true --version v1.18.2
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager --namespace cert-manager --timeout=300s

# Get the internal IP of rancher-mgmt cluster on cluster-bridge network for hostname
RANCHER_BRIDGE_IP=$(docker inspect k3d-rancher-mgmt-server-0 | jq -r '.[0].NetworkSettings.Networks["cluster-bridge"].IPAddress')

# Install rancher with proper TLS configuration for inter-cluster communication
echo "Installing Rancher..."
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
kubectl create namespace cattle-system

# Use localhost for external access and configure for inter-cluster communication
RANCHER_HOSTNAME="localhost"
echo "Using localhost hostname for external access"
echo "Internal IP for inter-cluster communication: $RANCHER_BRIDGE_IP"

helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=$RANCHER_HOSTNAME \
  --set bootstrapPassword=admin \
  --set ingress.tls.source=rancher \
  --set resources.requests.memory=512Mi \
  --set resources.limits.memory=1Gi

kubectl -n cattle-system rollout status deploy/rancher --timeout=600s
kubectl get pods --namespace cattle-system

# Create k3d mlflow cluster on mlflow-network
echo "Creating mlflow cluster..."
k3d cluster create mlflow \
  --network mlflow-network \
  --volume $PWD/.data-mlflow:/data \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --api-port 6551 \
  --servers 1

# Connect mlflow cluster to bridge network for inter-cluster communication
docker network connect cluster-bridge k3d-mlflow-server-0

k3d cluster list

# Switch context to mlflow cluster
kubectl config use-context k3d-mlflow

# Configure inter-cluster connectivity for Rancher cluster import
echo "Configuring inter-cluster connectivity..."

# Get the internal IP of rancher-mgmt cluster on cluster-bridge network
RANCHER_IP=$(docker inspect k3d-rancher-mgmt-server-0 | jq -r '.[0].NetworkSettings.Networks["cluster-bridge"].IPAddress')

if [ "$RANCHER_IP" = "null" ] || [ -z "$RANCHER_IP" ]; then
    echo "Warning: Could not find rancher-mgmt cluster IP on cluster-bridge network"
    echo "Manual configuration may be required for cluster import"
else
    echo "Found rancher-mgmt cluster internal IP: $RANCHER_IP"
    
    # Update Rancher hostname to use internal IP for inter-cluster communication
    echo "Updating Rancher hostname for inter-cluster communication..."
    kubectl config use-context k3d-rancher-mgmt
    
    helm upgrade rancher rancher-stable/rancher \
      --namespace cattle-system \
      --set hostname=localhost \
      --set "ingress.extraAnnotations.nginx\.ingress\.kubernetes\.io/server-alias"="$RANCHER_IP.sslip.io" \
      --set bootstrapPassword=admin \
      --set ingress.tls.source=rancher \
      --set resources.requests.memory=512Mi \
      --set resources.limits.memory=1Gi
    
    kubectl -n cattle-system rollout status deploy/rancher --timeout=300s
    
    # Switch back to mlflow cluster for import configuration
    kubectl config use-context k3d-mlflow

fi

# Wait for ingress to be created and ready
kubectl config use-context k3d-rancher-mgmt
echo "Waiting for Rancher ingress to be created..."
# Wait for ingress to exist (ingresses don't have ready conditions)
while ! kubectl get ingress rancher -n cattle-system >/dev/null 2>&1; do
    echo "Waiting for ingress to be created..."
    sleep 5
done
echo "Ingress found, proceeding with configuration..."

# Configure Rancher ingress for inter-cluster communication
echo "Configuring Rancher ingress for inter-cluster communication..."
echo "Adding ingress rule for $RANCHER_BRIDGE_IP.sslip.io..."

# Check if the ingress rule already exists to avoid duplicate entries
if ! kubectl get ingress rancher -n cattle-system -o jsonpath='{.spec.rules[*].host}' | grep -q "$RANCHER_BRIDGE_IP.sslip.io"; then
    # Use a temporary file to avoid shell quoting issues
    cat > /tmp/ingress-patch.json << EOF
[{
  "op": "add",
  "path": "/spec/rules/-",
  "value": {
    "host": "$RANCHER_BRIDGE_IP.sslip.io",
    "http": {
      "paths": [{
        "backend": {
          "service": {
            "name": "rancher",
            "port": {
              "number": 80
            }
          }
        },
        "path": "/",
        "pathType": "ImplementationSpecific"
      }]
    }
  }
}]
EOF
    kubectl patch ingress rancher -n cattle-system --type='json' --patch-file /tmp/ingress-patch.json
    echo "Added ingress rule for internal hostname"
else
    echo "Ingress rule for internal hostname already exists"
fi

# Add the internal hostname to TLS certificate
echo "Adding internal hostname to TLS certificate..."
if ! kubectl get ingress rancher -n cattle-system -o jsonpath='{.spec.tls[0].hosts[*]}' | grep -q "$RANCHER_BRIDGE_IP.sslip.io"; then
    # Use a temporary file to avoid shell quoting issues
    cat > /tmp/tls-patch.json << EOF
[{
  "op": "add",
  "path": "/spec/tls/0/hosts/-",
  "value": "$RANCHER_BRIDGE_IP.sslip.io"
}]
EOF
    kubectl patch ingress rancher -n cattle-system --type='json' --patch-file /tmp/tls-patch.json
    echo "Added internal hostname to TLS certificate"
    
    # Force cert-manager to regenerate the certificate with new hostname
    echo "Regenerating TLS certificate with internal hostname..."
    
    # Delete both the certificate and secret to force a clean regeneration
    kubectl delete certificate tls-rancher-ingress -n cattle-system --ignore-not-found=true
    kubectl delete secret tls-rancher-ingress -n cattle-system --ignore-not-found=true
    
    # Wait for cert-manager to recreate the certificate from the ingress annotations
    echo "Waiting for cert-manager to recreate certificate..."
    while ! kubectl get certificate tls-rancher-ingress -n cattle-system >/dev/null 2>&1; do
        echo "Waiting for certificate resource to be recreated..."
        sleep 5
    done
    
    # Wait for the certificate to be ready
    echo "Waiting for certificate to be ready..."
    kubectl wait --for=condition=ready certificate tls-rancher-ingress -n cattle-system --timeout=300s
    echo "TLS certificate regenerated successfully"
else
    echo "Internal hostname already in TLS certificate"
fi

# Verify connectivity from rancher-mgmt cluster
echo "Testing connectivity to internal hostname..."
kubectl run test-connectivity --image=curlimages/curl --rm -it --restart=Never -- curl --insecure -s https://$RANCHER_BRIDGE_IP.sslip.io/ping || echo "Connectivity test failed, but continuing..."

# mlflow
kubectl config use-context k3d-mlflow
kubectl rollout restart deployment/cattle-cluster-agent -n cattle-system

echo ""
echo "Setup complete!"
echo ""
echo "Access URLs:"
echo "- Rancher (external): https://localhost (admin/admin)"
if [ "$RANCHER_IP" != "null" ] && [ -n "$RANCHER_IP" ]; then
    echo "- Rancher (internal): https://$RANCHER_IP.sslip.io (admin/admin)"
fi
echo "- MLflow cluster services: http://localhost:8080"
echo ""
echo "Cluster contexts:"
echo "- rancher-mgmt: k3d-rancher-mgmt"
echo "- mlflow: k3d-mlflow"
echo ""
echo "Inter-cluster communication:"
echo "- Rancher server internal IP: $RANCHER_IP"
echo "- Internal hostname: $RANCHER_IP.sslip.io"
echo "- Rancher Server URL: https://$RANCHER_IP.sslip.io"
echo "- Bridge network: cluster-bridge (172.22.0.0/16)"
echo "- TLS certificate configured for both localhost and internal hostname"
echo ""
echo "Switch contexts with:"
echo "kubectl config use-context k3d-rancher-mgmt"
echo "kubectl config use-context k3d-mlflow"
echo ""
echo "Note: Cluster import will use the internal hostname automatically"
echo "for proper TLS certificate validation and connectivity."

    
echo ""
echo "To import mlflow cluster into Rancher:"
echo "1. Access Rancher at: https://localhost (external) or https://$RANCHER_IP.sslip.io (internal)"
echo "2. Go to Cluster Management > Import Existing"
echo "3. Copy the import command and run with the corrected server URL:"
echo ""
echo "# Example: Replace the server URL in the import command"
echo "curl --insecure -sfL https://localhost/v3/import/[CLUSTER_ID].yaml | kubectl apply -f -"
echo ""
echo "# The cattle-cluster-agent will automatically connect using the internal IP"
echo "# TLS certificate is configured for both localhost and $RANCHER_IP.sslip.io"
echo "# No additional manual patches are needed"
