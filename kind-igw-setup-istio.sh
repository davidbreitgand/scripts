#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

UHOME="/Users/davidbr"
export KUBECONFIG="${UHOME}/.kube/config"
KIND_CLUSTER_NAME="kind" # Change this if your kind cluster has a different name
GATEWAY_PROVIDER="istio" # Change this to your desired gateway controller, e.g., istio, contour, etc.
IGW_CHART_VERSION="v1.1.0" # Version of the Gateway API Inference Extension Helm chart

MODEL_1="meta-llama/Llama-3.1-8B-Instruct"
MODEL_2="deepseek/vllm-deepseek-r1"

MODEL_DEPLOYMENT_1="vllm-llama3-8b-instruct"
MODEL_DEPLOYMENT_2="vllm-deepseek-r1"

MODEL_1_LORA_1="food-review-1"
MODEL_2_LORA_1="ski-resorts"
MODEL_2_LORA_2="movie-critique"


YAML_HOME=/Users/davidbr/git/yaml
HOME=/Users/davidbr/git/clean/gateway-api-inference-extension 

# Istio specific setup script

# Install Istio as Gateway Controller
echo -e "${GREEN}▶ Installing Istio Gateway Controller...${NC}"
TAG=$(curl https://storage.googleapis.com/istio-build/dev/1.28-dev)
echo -e "${GREEN}▶ Using Istio version: ${TAG}${NC}"

wget https://storage.googleapis.com/istio-build/dev/${TAG}/istioctl-${TAG}-osx.tar.gz
# check whether wget succeeded
if [ $? -ne 0 ]; then
  echo -e "${RED}▶ Error: Failed to download istioctl.${NC}"
  exit 1
fi

tar -xvf istioctl-${TAG}-osx.tar.gz
# Check whether tar succeeded
if [ $? -ne 0 ]; then
  echo -e "${RED}▶ Error: Failed to extract istioctl.${NC}"
  exit 1
fi
./istioctl install --set tag=${TAG} --set hub=gcr.io/istio-testing --set values.pilot.env.ENABLE_GATEWAY_API_INFERENCE_EXTENSION=true
#check whether istioctl install succeeded
if [ $? -ne 0 ]; then
  echo -e "${RED}▶ Error: Failed to install Istio.${NC}"
  exit 1
fi
echo -e "${GREEN}▶ Istio Gateway Controller installed.${NC}"

sleep 1

# Deploy InferencePool and Endpoint Picker Extensions
echo -e "${GREEN}▶ Deploying InferencePool and EndpointPicker extensions...${NC}"
echo -e "${GREEN}▶ Using Helm chart that installs InferencePool named ${MODEL_1}... ${NC}"
echo -e "${GREEN}▶ The inference pool selects from endpoints with label ${RED}app: ${vllm-llama3-8b-instruct} ${GREEN} and listening on port 8000...${NC}" 
echo -e "${GREEN}▶ The Helm install command automatically installs the endpoint-picker and InferencePool along with provider specific resources...${NC}"

# Install Helm chart for InferencePool and EndpointPicker
helm install "${MODEL_1}" \
--set inferencePool.modelServers.matchLabels.app="${MODEL_DEPLOYMENT_1}" \
--set provider.name=$GATEWAY_PROVIDER \
--version $IGW_CHART_VERSION \
oci://registry.k8s.io/gateway-api-inference-extension/charts/inferencepool
# wait for deloyment to be ready
kubectl wait --for=condition=available --timeout=120s "deployment/${MODEL_DEPLOYMENT_1}-epp"

echo -e "${GREEN}▶ InferencePool and EndpointPicker extensions deployed.${NC}"

# Deploy the Inference Gateway
# Deploy detination rule to bypass TLS verification for demo purposes -- NO NEED: moved to helm chart
#echo -e "${GREEN}▶ Deploying Destination Rule...${NC}"
#kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/gateway/istio/destination-rule.yaml

echo -e "${GREEN}▶ Deploying Inference Gateway...${NC}"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/gateway/istio/gateway.yaml
echo -e "${GREEN}▶ Inference Gateway deployed.${NC}"
echo -e "${GREEN}▶ Waiting for the Inference Gateway to be ready...${NC}⏳"
if ./wait4inferencegw.sh "inference-gateway" "default" "180"; then
  echo -e "${GREEN}▶ Inference Gateway is ready, proceeding with deployment...${NC}"
else
  echo "${RED}▶ Inference Gateway did not become ready, aborting."
  exit 1
fi

sleep 2

# Deploy HTTPRoute to route traffic to the deployed InferencePool
echo -e "${GREEN}▶ Deploying HTTPRoute to route traffic to the InferencePool...${NC}"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api-inference-extension/raw/main/config/manifests/gateway/istio/httproute.yaml

echo -e "${GREEN}▶ Waiting for all HTTPRoutes to be ready...${NC}⏳"
for route in $(kubectl get httproute -o jsonpath='{.items[*].metadata.name}'); do
  echo -e "${GREEN}▶ Waiting for httproute '${route}'...${NC}"
  if ./wait4httproute.sh "$route" "default" "120"; then
    echo -e "${GREEN}✅ ${route} is ready.${NC}"
  else
    echo -e "${RED}❌ ${route} did not become ready in time. Aborting.${NC}"
    exit 1
  fi
done

# Test the setup
echo -e "${GREEN}▶ Testing the Gateway API Inference extensions setup...${NC}👀"
IP=$(kubectl get gateway/inference-gateway -o jsonpath='{.status.addresses[0].value}')
PORT=80

curl -i ${IP}:${PORT}/v1/completions -H 'Content-Type: application/json' -d '{
"model": "food-review-1",
"model": "${MODEL_1_LORA_1}",
"prompt": "Write as if you were a critic: San Francisco",
"max_tokens": 100,
"temperature": 0
}'
echo -e "\n${GREEN}▶ First test completed for ${MODEL_1_LORA_1}.${NC}"
sleep 2

# Deploy Second InferencePool and Endpoint Picker Extensions
echo -e "${GREEN}▶ Deploying InferencePool and EndpointPicker extensions...${NC}"
echo -e "${GREEN}▶ Using Helm chart that installs InferencePool named ${MODEL_2}... ${NC}"
echo -e "${GREEN}▶ The inference pool selects from endpoints with label ${RED}app: vllm-deepseek-r1 ${GREEN} and listening on port 8000...${NC}" 
echo -e "${GREEN}▶ The Helm install command automatically installs the endpoint-picker and InferencePool along with provider specific resources...${NC}⏳"

helm install "${MODEL_2}" \
--set inferencePool.modelServers.matchLabels.app="${MODEL_2}" \
--set provider.name="$GATEWAY_PROVIDER" \
--version "$IGW_CHART_VERSION" \
oci://registry.k8s.io/gateway-api-inference-extension/charts/inferencepool
# wait for deloyment to be ready
kubectl wait --for=condition=available --timeout=120s "deployment/${MODEL_2}-epp"
echo -e "${GREEN}▶ InferencePool and EndpointPicker extensions deployed.${NC}"

# undeploy previous BBR release
echo -e "${GREEN}▶ Uninstalling any previous Body Based Router (BBR) release...${NC}"
helm uninstall body-based-router 2>/dev/null || echo -e "${YELLOW}▶ No previous BBR release found, continuing...${NC}"

# deploy BBR
echo -e "${GREEN}▶ Deploying Body Based Router (BBR) with Istio provider...${NC}"
helm install body-based-router \
--set provider.name=istio \
--version v1.0.0 \
oci://registry.k8s.io/gateway-api-inference-extension/charts/body-based-routing

#delete llm-route
echo -e "${GREEN}▶ Deleting existing HTTPRoute 'llm-route' to test BBR...${NC}"
kubectl delete httproute "llm-route"
echo -e "${GREEN}▶ Deleted existing HTTPRoute.${NC}"
sleep 1

#deploy HTML Routes for demonstrating BBR
echo -e "${GREEN}▶ Deploy httproutes for testing BBR.${NC}"
#kubectl apply -f "${YAML_HOME}/two-routes.yaml" #does not have definitions for LoRAs uncomment as needed
kubectl apply -f "${YAML_HOME}/multi-model-multi-lora-sim.yaml"
sleep 2
# Confirm that the HTTPRoute status conditions include Accepted=True and ResolvedRefs=True
echo -e "${GREEN}▶ Confirming that the HTTPRoutes for BBR are ready...${NC}👀"

#wait until all httproutes are ready
for route in $(kubectl get httproute -o jsonpath='{.items[*].metadata.name}'); do
  echo -e "${GREEN}▶ Waiting for httproute '${route}'...${NC}"
  if ./wait4httproute.sh "$route" "default" "120"; then
    echo -e "${GREEN}✅ ${route} is ready.${NC}"
  else
    echo -e "${RED}❌ ${route} did not become ready in time. Aborting.${NC}"
    exit 1
  fi
done 

#Test BBR setup
echo -e "\n${GREEN}▶ Testing Body Based Routing setup...${NC}"
sleep 1

for i in {1..3}; do
	echo -e "\n ${GREEN}▶ ATTEMPT ${i}: Testing routing to ${MODEL_1} InferencePool via BBR...${NC}"
	if ./model-test.sh "${MODEL_1}"; then
		echo -e "${GREEN}✅ Success on attempt ${i}${NC}"
		break
	else
		echo -e "${RED}❌ Attempt ${i} failed, retrying...${NC}"
        sleep $((i * 4))
	fi
done

sleep 1

for i in {1..3}; do
	echo -e "\n ${GREEN}▶ ATTEMPT ${i}: Testing routing to ${MODEL_2} InferencePool via BBR...${NC}"
	if ./model-test.sh "${MODEL_2}"; then
		echo -e "${GREEN}✅ Success on attempt ${i}${NC}"
		break
	else
		echo -e "${RED}❌ Attempt ${i} failed, retrying...${NC}"
        sleep $((i * 3))
	fi
done

sleep 1

#Testing LoRAs
for i in {1..3}; do
	echo -e "\n ${GREEN}▶ ATTEMPT ${i}: Testing routing to LoRA ${MODEL_1_LORA_1} for base model ${MODEL_1} InferencePool via BBR...${NC}"
	if ./model-test.sh "${MODEL_1_LORA_1}"; then
		echo -e "${GREEN}✅ Success on attempt ${i}${NC}"
		break
	else
		echo -e "${RED}❌ Attempt ${i} failed, retrying...${NC}"
        sleep $((i * 3))
	fi
done

for i in {1..3}; do
	echo -e "\n ${GREEN}▶ ATTEMPT ${i}: Testing routing to LoRA ${MODEL_2_LORA_1} for base model ${MODEL_2} InferencePool via BBR...${NC}"
	if ./model-test.sh "${MODEL_2_LORA_1}"; then
		echo -e "${GREEN}✅ Success on attempt ${i}${NC}"
		break
	else
		echo -e "${RED}❌ Attempt ${i} failed, retrying...${NC}"
        sleep $((i * 3))
	fi
done

for i in {1..3}; do
	echo -e "\n ${GREEN}▶ ATTEMPT ${i}: Testing routing to LoRA ${MODEL_2_LORA_2} for base model ${MODEL_2} InferencePool via BBR...${NC}"
	if ./model-test.sh "${MODEL_2_LORA_2}"; then
		echo -e "${GREEN}✅ Success on attempt ${i}${NC}"
		break
	else
		echo -e "${RED}❌ Attempt ${i} failed, retrying...${NC}"
        sleep $((i * 3))
	fi
done


#Remove temporary istioctl files
echo -e "\n ${GREEN}Removing istioctl-${TAG}-osx.tar.gz and istioctl...${NC}"
rm -rf "istioctl-${TAG}-osx.tar.gz"* "istioctl"*

echo -e "${GREEN}▶ Gateway API Inference Extension with Istio setup complete.${NC}"
