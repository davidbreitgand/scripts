#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VERSION="v1.1.0"

KIND_CLUSTER_NAME="kind" # Change this if your kind cluster has a different name

# This script sets up IGW on an existing kind cluster with MetalLB in Colima
# This script is intended for MacOS with Apple Silicon using Colima as the Docker container runtime for kind

# Check that an appropriate kind cluster exist
echo -e "${GREEN}▶ Verifying that kind cluster '${KIND_CLUSTER_NAME}' exists...${NC}👀"

EXISTING_CLUSTERS=$(kind get clusters)
if ! echo "$EXISTING_CLUSTERS" | grep -q "^${KIND_CLUSTER_NAME}$"; then
  echo -e "${RED}▶ Error: Kind cluster named '${KIND_CLUSTER_NAME}' does not exist. Please create it first.${NC}"
  exit 1
fi

#Check that MetalLB is installed in the kind cluster
echo -e "${GREEN}▶ Verifying that MetalLB is installed in the kind cluster...${NC}👀"

METALLB_NAMESPACE="metallb-system"
if ! kubectl get namespace "$METALLB_NAMESPACE" &> /dev/null; then
  echo -e "${RED}▶ Error: MetalLB is not installed in the kind cluster. Please install it first.${NC}"
  exit 1
fi  

# Check that MetalLB has IP address pool configured
echo -e "${GREEN}▶ Verifying that MetalLB has an IPAddressPool configured...${NC}👀"
sleep 1

IP_POOL_COUNT=$(kubectl get ipaddresspools -n "$METALLB_NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [ "$IP_POOL_COUNT" -eq 0 ]; then
  echo -e "${RED}▶ Error: No IPAddressPool found in MetalLB. Please configure an IP address pool first.${NC}"
  exit 1
fi

sleep 1

#check that MetalLB has IP as expected
echo -e "${GREEN}▶ Checking that the LoadBalancer service obtained an ingress IP...${NC}👀"
LB_IP=$(kubectl get svc/foo-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo -e "${GREEN}▶ LoadBalancer ingress IP: $LB_IP${NC}"
echo -e "${GREEN}▶ Kind cluster and MetalLB setup verified.${NC}"

# If LB_IP is empty, exit with error
if [ -z "$LB_IP" ]; then
  echo -e "${RED}▶ Error: LoadBalancer service did not obtain an ingress IP. Please check MetalLB configuration.${NC}"
  exit 1
fi
echo -e "${GREEN}▶ MetalLB verification complete. You can now access the LoadBalancer service at IP: $LB_IP${NC}"

sleep 1

# Install Gateway API CRDs
echo -e "${GREEN}▶ Installing Gateway API CRDs (standard channel)...${NC}"
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml
for crd in backendtlspolicies.gateway.networking.k8s.io \
		gatewayclasses.gateway.networking.k8s.io \
		gateways.gateway.networking.k8s.io \
		grpcroutes.gateway.networking.k8s.io \
		httproutes.gateway.networking.k8s.io \
		referencegrants.gateway.networking.k8s.io \
		gatewayclasses.gateway.networking.k8s.io \
		httproutes.gateway.networking.k8s.io; do
	kubectl wait --for=condition=Established --timeout=60s crd/"${crd}"
done
echo -e "${GREEN}▶ Gateway API CRDs installed.${NC}"
sleep 1

# Now we will install IGW by mimicking https://gateway-api-inference-extension.sigs.k8s.io/guides/
# This script installs uses vLLM Simulator Model Server as backend and Istio as the gateway controller 
# Change the script as needed for your own backend services and gateway controller

# Install first vLLM Simulator Model Server
echo -e "${GREEN}▶ Installing vLLM Simulator Model Server...${NC}"
#kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api-inference-extension/refs/tags/v1.0.2/config/manifests/vllm/sim-deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api-inference-extension/refs/tags/v1.1.0/config/manifests/vllm/sim-deployment.yaml

# Wait for the deployment to be ready
kubectl wait --for=condition=available --timeout=120s deployment/vllm-llama3-8b-instruct
echo -e "${GREEN}▶ vLLM Simulator Model Server installed.${NC}"

# Install second vLLM Simulator Model server 
echo -e "${GREEN}▶ Installing second vLLM Simulator Model Server...${NC}"
kubectl apply -f ~/git/yaml/deepseek-sim-deployment.yaml
# Wait for the deployment to be ready
kubectl wait --for=condition=available --timeout=120s deployment/vllm-deepseek-r1
echo -e "${GREEN}▶ Second vLLM Simulator Model Server installed.${NC}"

#install Gateway API Inference Extension CRDs
#echo -e "${GREEN}▶ Installing Gateway API Inference Extension CRDs...${NC}"
#kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/v1.0.2/v1-manifests.yaml # These manifests do not include inference objectives
#kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/v1.0.2/manifests.yaml #these manifests include inference objectives
#kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/v1.1.0/manifests.yaml
echo -e "${GREEN}▶ Applying Gateway API Inference Extension CRDs version ${VERSION}...${NC}"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/releases/download/${VERSION}/manifests.yaml
for crd in inferencepools.inference.networking.k8s.io \
		inferencepools.inference.networking.x-k8s.io; do
	kubectl wait --for=condition=Established --timeout=60s crd/$crd
done
echo -e "${GREEN}▶ Gateway API Inference Extension CRDs version ${VERSION} installed.${NC}"
sleep 1


