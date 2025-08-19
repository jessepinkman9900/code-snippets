#!/bin/bash

echo "Cleaning up k3d clusters and Docker networks..."

# Delete k3d clusters
k3d cluster delete rancher-mgmt
k3d cluster delete mlflow

# Remove Docker networks
docker network rm rancher-network 2>/dev/null || true
docker network rm mlflow-network 2>/dev/null || true
docker network rm cluster-bridge 2>/dev/null || true

# Clean up data directories
rm -rf .data-rancher-mgmt
rm -rf .data-mlflow

echo "Cleanup complete!"
