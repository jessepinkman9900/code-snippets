# K3D + Ray + MLflow

## Setup
```bash
# create cluster
just k3d-create

# apply helmfile - istio, kuberay, raycluster
just helmfile-apply

# apply ingress and service rules
kubectl apply -f k8s/traefik/service.yaml
kubectl apply -f k8s/traefik/ingress.yaml
kubectl apply -f k8s/ray/cluster-1/ingress.yaml

# debug
TRAEFIK_POD=$(kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n kube-system "$TRAEFIK_POD" 9000:9000
```

## Notes
- traefik dashboard rev proxy isnt working. use port forward
