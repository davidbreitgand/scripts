#!/opt/homebrew/bin/bash

#Prerequisite bash4+

set -e
#set -x

# CONFIGURATION
KIND_SINGLE_NODE_CONFIG="/tmp/kind-single-node-config.yaml"
KIND_MULTI_NODE_CONFIG="/tmp/kind-multi-node-config"
METALLB_KIND_CONFIG="/tmp/metallb-kind-config.yaml"
METALLB_VERSION="v0.14.5"
METALLB_NAMESPACE="metallb-system"
# Set the test app label selector to test service of the type LoadBalancer on a kind cluster in Colima
TEST_APP_LABEL="http-echo"
TIMEOUT=300s

# COLORS
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Show help 
show_help() {
  echo -e "${GREEN}▶ Help ${NC} ❓"
  echo "Usage: $0 <METALLB_VERSION> <KIND_NODE_IMAGE> [-h|--help]"
  echo "  METALLB_VERSION: The MetalLB version to use (e.g., v0.13.7)"
  echo "  KIND_NODE_IMAGE: The Kind node image to use (e.g., kindest/node:v1.28.0@sha256:xyz...)"
  echo "  -h|--help: Show this help message "
  exit 1
}

# Check for the help argument
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  show_help
fi

# Check if METALLB_VERSION_VERSION and KIND_NODE_IMAGE are provided as arguments.
if [ -z "$1" ] || [ -z "$2" ]; then
  echo -e "${RED} Error: Missing arguments. Use -h or --help ${NC} ℹ️ "
  show_help
fi


#Set configuration parameters
export METALLB_VERSION="$1"
export KIND_NODE_IMAGE="$2"


# Execute the colima list command and capture the output.
colima_status=$(colima list)

# Use grep to check if the line containing "default" also contains "Running".
if echo "$colima_status" | grep -iq "^default.*Running"; then
  # If the default colima VM is running, set COLIMA_NEEDS_SETUP=1.
  export COLIMA_NEEDS_SETUP=0
  echo -e "${GREEN}▶ Colima (default machine) is running. Setting COLIMA_NEEDS_SETUP=0 ${NC} 🛠️"
  echo -e "${GREEN}▶ ⚠️ Stop the script, then stop and delete default colima VM before running this script if you want a clean slate Colima VM${NC}⚠️ "
  sleep 2
else
  # Otherwise, set COLIMA_READY=0.
  export COLIMA_NEEDS_SETUP=1
  echo -e "${GREEN}▶ Colima Colima (default) is not running. Setting COLIMA_READY=0${NC}🛠️"
fi

# (Optional) Verify the environment variable is set correctly.
echo "COLIMA_NEEDS_SETUP: $COLIMA_NEEDS_SETUP"


if [[ "$COLIMA_NEEDS_SETUP" == "1" ]]; then
  echo -e "${GREEN}▶ Starting Colima with networking enabled...${NC}🚀"
  colima start --runtime docker --cpu 8 --memory 16 --disk 200 --network-address
  # Wait for Colima to fully initialize
  sleep 5
fi


colima_status=$(colima status 2>&1)
echo "COLIMA STATUS\n $colima_status"

#multinode cluster is nor needed necessarily. I added it here to create a testing environment that more closely resembles production;
#maybe will also add Calico to play w/network policies in the future

#echo -e "${GREEN}▶ Creating kind config...${NC}🛠️"
#cat <<EOF > $KIND_MULTI_NODE_CONFIG
#kind: Cluster
#apiVersion: kind.x-k8s.io/v1alpha4
#name: kind
#nodes:
#  - role: control-plane
#    image: $KIND_NODE_IMAGE
#  - role: worker
#    image $KIND_NODE_IMAGE
#  - role: worker  
#    image $KIND_NODE_IMAGE
#EOF


echo -e "${GREEN}▶ Creating kind config $KIND_SINGLE_NODE_CONFIG...${NC}🛠️"
cat <<EOF > $KIND_SINGLE_NODE_CONFIG
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kind
nodes:
  - role: control-plane
    image: $KIND_NODE_IMAGE
EOF

echo -e "${GREEN}▶ Deploy the kind cluster...${NC} 🚀"
if ! kind get clusters | grep -iw "^kind$" 2>&1; then 
  echo -e "${GREEN}▶ Creating kind cluster with $KIND_NODE_IMAGE...${NC}🚀"
  kind create cluster --config $KIND_SINGLE_NODE_CONFIG
else 
  echo -e "${GREEN}▶ Kind cluster already exists ${NC} restoring current context to be kind-kind ✅"
  #restore kubectl context context to point to this cluster
  kubectl config use-context kind-kind
fi

export colima_host_ip=$(ifconfig bridge100 | grep "inet " | cut -d' ' -f2)
echo -e "${GREEN}▶ Colima host IP: $colima_host_ip${NC}"

sleep 1

export colima_vm_ip=$(colima list | grep docker | awk '{print $8}')
echo -e "${GREEN}▶ Colima VM IP: $colima_vm_ip${NC}"

sleep 1

export colima_kind_cidr=$(docker network inspect kind -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+')
echo -e "${GREEN}▶ Kind CIDR: $colima_kind_cidr${NC}"

sleep 1

export colima_kind_cidr_short=$(echo $colima_kind_cidr | cut -d. -f1,2)
echo -e "${GREEN}▶ Kind CIDR (short): $colima_kind_cidr_short${NC}"

sleep 1

export colima_vm_iface=$(colima ssh -- ip -br address show to $colima_vm_ip | cut -d' ' -f1)
echo -e "${GREEN}▶ Colima VM iface: $colima_vm_iface${NC}"

sleep 1

export colima_kind_iface=$(colima ssh -- ip -br address show to $colima_kind_cidr | cut -d' ' -f1)
echo -e "${GREEN}▶ Colima Kind iface: $colima_kind_iface${NC}"


echo -e "${GREEN}▶ Configuring Mac routing to access Colima VM directly from the Mac...${NC}🛠️"


set +e #route returns with 1 if the route is not found
route_output=$(route get "$colima_kind_cidr" 2>/dev/null | grep "gateway: $colima_vm_ip")
set -e

echo "$route_output"

if [ -n "$route_output" ]; then
  echo -e "${GREEN}▶ Route for $colima_kind_cidr via $colima_vm_ip already exists. ${NC} ✅"
else
  route_command_string="route -nv add -net $colima_kind_cidr $colima_vm_ip"
  echo -e "${GREEN}▶ Configuring route for $colima_kind_cidr via $colima_vm_ip... ${NC} 🛠️"
  echo "$route_command_string"
  sudo route -nv add -net $colima_kind_cidr $colima_vm_ip
  # Check the exit code
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}▶ The route from Mac to Colima gateway added successfully. ${NC} ✅"
  else
    echo -e "${GREEN}▶ Failed to add the route from Mac to Colima gateway. ${NC} ❌"
  fi
fi

sleep 2

if [[ "$COLIMA_NEEDS_SETUP" == "1" ]]; then
  echo -e "${GREEN}▶ ▶️ Installing iputils-ping (optional)${NC}🛠️"
  ssh_cmd="sudo apt update; sudo apt install iputils-ping"
  colima ssh -- bash -c "$ssh_cmd"
  echo -e "${GREEN}▶ ▶️ Configuring routing inside Colima VM...${NC}🛠️"
  #ssh_cmd="sudo iptables -A FORWARD -s $colima_host_ip -d $colima_kind_cidr -i $colima_vm_iface -o $colima_kind_iface -j ACCEPT"
  #echo -e "${GREEN}▶ ▶️ Running routing command inside Colima VM: \n${RED}$ssh_cmd${NC}"
  #colima ssh -- bash -c "$ssh_cmd"
  ssh_cmd="sudo iptables -I FORWARD -s $colima_host_ip -d $colima_kind_cidr -j ACCEPT" #needed?
  echo -e "${GREEN}▶ ▶️ Running routing command inside Colima VM: \n${RED}$ssh_cmd${NC}"
  colima ssh -- bash -c "$ssh_cmd"  
  echo -e "${GREEN}▶ ▶️ Installing iputils-ping (optional)${NC}🛠️"
  ssh_cmd="sudo apt update; sudo apt install iputils-ping"
  colima ssh -- bash -c "$ssh_cmd"
  echo -e "${GREEN}▶ ▶️ Installing QEMU (to be able to build for linux/amd64) ${NC}🛠️"
  ssh_cmd="sudo apt install -y qemu-user qemu-user-static"
  colima ssh -- bash -c "$ssh_cmd"
  #echo -e "${GREEN}▶ ▶️ Installing insecure Docker registry... ${NC}🚀"
  #ssh_cmd="sudo mkdir -p /etc/docker; echo '{"insecure-registries":["localhost:5000"]}' | sudo tee /etc/docker/daemon.json; sudo systemctl restart docker"
  #colima ssh -- bash -c "$ssh_cmd"
fi



echo -e "${GREEN}▶ Installing MetalLB...${NC}🚀"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml

echo -e "${GREEN}▶ Waiting for MetalLB pods...${NC}⏳"
kubectl wait --namespace metallb-system \
             --for=condition=ready pod \
             --selector=app=metallb \
             --timeout=${TIMEOUT}


KIND_SUBNET=$(docker network inspect kind -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+')
KIND_PREFIX=$(echo $KIND_SUBNET | cut -d. -f1-3)
METALLB_RANGE_START="${KIND_PREFIX}.200"
METALLB_RANGE_END="${KIND_PREFIX}.250"

echo -e "${GREEN}▶ Creating MetalLB config...${NC}🛠️"
echo -e "${GREEN}▶ Using MetalLB range: ${METALLB_RANGE_START}-${METALLB_RANGE_END}${NC} 🛠️"

#cat <<EOF > $METALLB_CONFIG
#apiVersion: metallb.io/v1beta1
#kind: IPAddressPool
#metadata:
#  name: colima-kind-pool
#  namespace: $METALLB_NAMESPACE
#spec:
#  addresses:
#  - ${METALLB_RANGE_START}-${METALLB_RANGE_END}
#---
#apiVersion: metallb.io/v1beta1
#kind: L2Advertisement
#metadata:
#  name: l2adv
#  namespace: $METALLB_NAMESPACE
#EOF


# Double check if METALLB_KIND_CONFIG, METALLB_RANGE_START, and METALLB_RANGE_END are set
if [ -z "${METALLB_KIND_CONFIG}" ] || [ -z "${METALLB_RANGE_START}" ] || [ -z "${METALLB_RANGE_END}" ]; then
  echo -e "${GREEN}▶ Error: $METALLB_KIND_CONFIG, $METALLB_RANGE_START, and $METALLB_RANGE_END are not set. ${NC} ❌"
  exit 1
fi

# Create a temporary file to store the modified /tmp/metallb-config.yaml
tmp_file=$(mktemp)

# Perform the replacements using sed and stream to the temporary file
# Escape the '.'
sed "s#NETWORK_PREFIX\.200#${METALLB_RANGE_START}#g" "${METALLB_KIND_CONFIG}" | sed "s#NETWORK_PREFIX\.250#${METALLB_RANGE_END}#g" | sed "s#NETWORK_PREFIX\.200-NETWORK_PREFIX\.250#${METALLB_RANGE_START}-${METALLB_RANGE_END}#g" > "${tmp_file}"

# Check if the sed commands were successful
if [ $? -ne 0 ]; then
  echo -e "${GREEN} Error: sed command failed.${NC} ❌"
  rm -f "${tmp_file}"
  exit 1
fi

# Replace the original file with the temporary file
mv "${tmp_file}" "${METALLB_KIND_CONFIG}"

# Verify that the file replacement was successful
if [ $? -ne 0 ]; then
  echo "${GREEN}Error: mv command failed to replace the original file.${NC} ❌"
  exit 1
fi

echo -e "${GREEN}▶ Successfully reconfigured network prefix in ${METALLB_KIND_CONFIG}... ✅" 


echo -e "${GREEN}▶ Applying MetalLB configuration...${NC}🚀"
kubectl apply -f $METALLB_KIND_CONFIG

#test the setup

echo -e "${GREEN}▶ Deploying the test LoadBalancer service...${NC}🚀"
kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/usage.yaml

echo -e "${GREEN}▶ Waiting for the LoadBalancer service to be ready...${NC}⏳"

echo -e "${GREEN}▶ Waiting for the backend pods to be ready...${NC}⏳"

sleep 2

kubectl wait --namespace default \
             --for=condition=ready pod \
             --selector=app=http-echo \
             --timeout=${TIMEOUT}

echo -e "${GREEN}▶ Finally, lets test MetalLB using a simple LoadBalancier service foo-service!... ${NC}🙂"

echo -e "${GREEN}▶ Checking that the LoadBalancer service obtained an ingress IP...${NC}👀"
LB_IP=$(kubectl get svc/foo-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo -e "${GREEN}▶ LoadBalancer ingress IP: $LB_IP${NC}"
#TODO: add logic to check validity of the address

# Initialize counters
foo_count=0
bar_count=0

#initialize test backend pod names
foo_app="foo-app"
bar_app="bar-app"

# Capture all relevant lines

output_lines=() # Initialize as an array
for _ in {1..10}; do
  result=$(curl -s "http://${LB_IP}:5678" | grep -Eo 'foo-app|bar-app')
  output_lines+=("$result")
done

echo "${output_lines[@]}"

set +e
for line in  "${output_lines[@]}"; do
  cleaned=$(echo "$line" | tr -d '\r' | xargs)
  #echo "Processing: [$cleaned]"
  if [[ "$cleaned" == *"$foo_app"* ]]; then
    ((foo_count++))
    #echo "foo_count: $foo_count"
  elif [[ "$cleaned" == *"$bar_app"* ]]; then
    ((bar_count++))
    #echo "bar_count: $bar_count"
  else
    echo "test failed: unexpected [$line]"
    exit 0
  fi
done
set -e

total_count=$((foo_count + bar_count))

#echo "$total_count"

if [[ "$total_count" -eq 10 && "$bar_count" -gt 0 && "$foo_count" -gt 0 ]]; then
  echo -e "Test succeeded ✅"
else
  echo -e "Test failed ❌"
fi

#clean temporary configuration files for kind and metallb

files_to_remove=("$METALLB_KIND_CONFIG" "$KIND_SINGLE_NODE_CONFIG")
echo -e "${GREEN}▶ Cleaning temporary configuration files: ${files_to_remove[@]} ${NC} ✨"
rm -rf "${files_to_remove[@]}"

set +e
exit 0




