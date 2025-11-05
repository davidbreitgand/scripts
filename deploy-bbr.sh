#!/bin/bash

# Reusable Helm deployment script for body-based-router on a local kind cluster with Istio
# Usage: ./deploy-bbr.sh [release-name] [namespace]

# Default values
RELEASE_NAME=${1:-body-based-router}
NAMESPACE=${2:-default}
CHART_PATH="./config/charts/body-based-routing"

# Validate Helm availability
if ! command -v helm &> /dev/null; then
    echo "Error: Helm is not installed or not in PATH." >&2
    exit 1
fi

# Validate git availability
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed or not in PATH." >&2
    exit 1
fi

# Generate dynamic image tag using git describe
tag=$(git describe --tags --dirty --always)

# Construct Helm command
CMD="helm install $RELEASE_NAME $CHART_PATH \
  --namespace $NAMESPACE \
  --set provider.name=istio \
  --set inferenceGateway.name=inference-gateway \
  --set bbr.image.tag=$tag \
  --set bbr.image.pullPolicy=IfNotPresent"

# Print and execute the command
echo "Executing: $CMD"
$CMD
