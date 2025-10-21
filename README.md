# scripts
Useful scripts that other people may also find useful

* kind-metallb-colima-full.sh is inspired by [this 2023 blog](https://www.opencredo.com/blogs/building-the-best-kubernetes-test-cluster-on-macos). It sets up a `kind`-based developent environment on Mac with Apple Silicone, Colima, and MetalLB. The script automates the steps in the blog while adapting for 2025 and adding some additinal configurations and definitions.   

* Sample successful output of the script

`./kind-metallb-colima-full.sh`

```log
⚠️  Warning: Using default values for missing arguments.
METALLB_VERSION=v0.14.5, KIND_NODE_IMAGE=kindest/node:v1.30.13
▶ Using METALLB_VERSION=v0.14.5, KIND_NODE_IMAGE=kindest/node:v1.30.13
WARN[0000] No instance found. Run `colima start` to create an instance. 
▶ Colima Colima (default) is not running. Setting COLIMA_READY=0🛠️
COLIMA_NEEDS_SETUP: 1
▶ Starting Colima with networking enabled...🚀
INFO[0000] starting colima                              
INFO[0000] runtime: docker                              
INFO[0001] creating and starting ...                     context=vm
INFO[0026] provisioning ...                              context=docker
INFO[0028] starting ...                                  context=docker
INFO[0050] done                                         
COLIMA STATUS\n time="2025-10-21T20:19:13+03:00" level=info msg="colima is running using macOS Virtualization.Framework"
time="2025-10-21T20:19:13+03:00" level=info msg="arch: aarch64"
time="2025-10-21T20:19:13+03:00" level=info msg="runtime: docker"
time="2025-10-21T20:19:13+03:00" level=info msg="mountType: virtiofs"
time="2025-10-21T20:19:13+03:00" level=info msg="address: 192.168.64.2"
time="2025-10-21T20:19:13+03:00" level=info msg="docker socket: unix:///Users/davidbr/.colima/default/docker.sock"
time="2025-10-21T20:19:13+03:00" level=info msg="containerd socket: unix:///Users/davidbr/.colima/default/containerd.sock"
▶ Creating kind config /tmp/kind-single-node-config.yaml...🛠️
▶ Deploy the kind cluster... 🚀
No kind clusters found.
▶ Creating kind cluster with kindest/node:v1.30.13...🚀
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.30.13) 🖼 
 ✓ Preparing nodes 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
▶ Colima host IP: 192.168.64.1
▶ Colima VM IP: 192.168.64.2
▶ Kind CIDR: 172.18.0.0/16
▶ Kind CIDR (short): 172.18
▶ Colima VM iface: col0
▶ Colima Kind iface: br-e3531af22538
▶ Configuring Mac routing to access Colima VM directly from the Mac...🛠️

▶ Configuring route for 172.18.0.0/16 via 192.168.64.2...  🛠️
route -nv add -net 172.18.0.0/16 192.168.64.2
Password:
u: inet 172.18.0.0; u: inet 192.168.64.2; u: inet 255.255.0.0; RTM_ADD: Add Route: len 132, pid: 0, seq 1, errno 0, flags:<UP,GATEWAY,STATIC>
locks:  inits: 
sockaddrs: <DST,GATEWAY,NETMASK>
 172.18.0.0 192.168.64.2 255.255.0.0
add net 172.18.0.0: gateway 192.168.64.2
▶ The route from Mac to Colima gateway added successfully.  ✅
▶ ▶️ Installing iputils-ping (optional)🛠️
Get:1 http://ports.ubuntu.com/ubuntu-ports noble InRelease [256 kB]
Get:2 https://download.docker.com/linux/ubuntu noble InRelease [48.5 kB]
Get:3 https://download.docker.com/linux/ubuntu noble/stable arm64 Packages [33.2 kB]
Get:4 http://ports.ubuntu.com/ubuntu-ports noble-updates InRelease [126 kB]
Get:5 http://ports.ubuntu.com/ubuntu-ports noble-backports InRelease [126 kB]
Get:6 http://ports.ubuntu.com/ubuntu-ports noble-security InRelease [126 kB]
Get:7 http://ports.ubuntu.com/ubuntu-ports noble/main arm64 Packages [1377 kB]
Get:8 http://ports.ubuntu.com/ubuntu-ports noble/main Translation-en [513 kB]
Get:9 http://ports.ubuntu.com/ubuntu-ports noble/universe arm64 Packages [15.3 MB]
Get:10 http://ports.ubuntu.com/ubuntu-ports noble/universe Translation-en [5982 kB]
Get:11 http://ports.ubuntu.com/ubuntu-ports noble/restricted arm64 Packages [91.9 kB]
Get:12 http://ports.ubuntu.com/ubuntu-ports noble/restricted Translation-en [18.7 kB]
Get:13 http://ports.ubuntu.com/ubuntu-ports noble/multiverse arm64 Packages [223 kB]
Get:14 http://ports.ubuntu.com/ubuntu-ports noble/multiverse Translation-en [118 kB]
Get:15 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 Packages [1617 kB]
Get:16 http://ports.ubuntu.com/ubuntu-ports noble-updates/main Translation-en [291 kB]                                                            
Get:17 http://ports.ubuntu.com/ubuntu-ports noble-updates/universe arm64 Packages [1437 kB]                                                       
Get:18 http://ports.ubuntu.com/ubuntu-ports noble-updates/universe Translation-en [301 kB]                                                        
Get:19 http://ports.ubuntu.com/ubuntu-ports noble-updates/restricted arm64 Packages [2988 kB]                                                     
Get:20 http://ports.ubuntu.com/ubuntu-ports noble-updates/restricted Translation-en [486 kB]                                                      
Get:21 http://ports.ubuntu.com/ubuntu-ports noble-updates/multiverse arm64 Packages [28.7 kB]                                                     
Get:22 http://ports.ubuntu.com/ubuntu-ports noble-updates/multiverse Translation-en [5564 B]                                                      
Get:23 http://ports.ubuntu.com/ubuntu-ports noble-backports/main arm64 Packages [40.3 kB]                                                         
Get:24 http://ports.ubuntu.com/ubuntu-ports noble-backports/main Translation-en [9208 B]                                                          
Get:25 http://ports.ubuntu.com/ubuntu-ports noble-backports/universe arm64 Packages [28.9 kB]                                                     
Get:26 http://ports.ubuntu.com/ubuntu-ports noble-backports/universe Translation-en [17.5 kB]                                                     
Get:27 http://ports.ubuntu.com/ubuntu-ports noble-security/main arm64 Packages [1314 kB]                                                          
Get:28 http://ports.ubuntu.com/ubuntu-ports noble-security/main Translation-en [205 kB]                                                           
Get:29 http://ports.ubuntu.com/ubuntu-ports noble-security/universe arm64 Packages [891 kB]                                                       
Get:30 http://ports.ubuntu.com/ubuntu-ports noble-security/universe Translation-en [202 kB]                                                       
Get:31 http://ports.ubuntu.com/ubuntu-ports noble-security/restricted arm64 Packages [2787 kB]                                                    
Get:32 http://ports.ubuntu.com/ubuntu-ports noble-security/restricted Translation-en [448 kB]                                                     
Get:33 http://ports.ubuntu.com/ubuntu-ports noble-security/multiverse arm64 Packages [28.5 kB]                                                    
Get:34 http://ports.ubuntu.com/ubuntu-ports noble-security/multiverse Translation-en [5708 B]                                                     
Fetched 37.5 MB in 8s (4525 kB/s)                                                                                                                 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
39 packages can be upgraded. Run 'apt list --upgradable' to see them.
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  iputils-ping
0 upgraded, 1 newly installed, 0 to remove and 39 not upgraded.
Need to get 44.6 kB of archives.
After this operation, 181 kB of additional disk space will be used.
Get:1 http://ports.ubuntu.com/ubuntu-ports noble-updates/main arm64 iputils-ping arm64 3:20240117-1ubuntu0.1 [44.6 kB]
Fetched 44.6 kB in 0s (151 kB/s)     
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package iputils-ping.
(Reading database ... 17239 files and directories currently installed.)
Preparing to unpack .../iputils-ping_3%3a20240117-1ubuntu0.1_arm64.deb ...
Unpacking iputils-ping (3:20240117-1ubuntu0.1) ...
Setting up iputils-ping (3:20240117-1ubuntu0.1) ...
▶ ▶️ Configuring routing inside Colima VM...🛠️
▶ ▶️ Running routing command inside Colima VM: 
sudo iptables -I FORWARD -s 192.168.64.1 -d 172.18.0.0/16 -j ACCEPT
▶ ▶️ Installing iputils-ping (optional)🛠️
Hit:1 https://download.docker.com/linux/ubuntu noble InRelease
Hit:2 http://ports.ubuntu.com/ubuntu-ports noble InRelease
Hit:3 http://ports.ubuntu.com/ubuntu-ports noble-updates InRelease
Hit:4 http://ports.ubuntu.com/ubuntu-ports noble-backports InRelease
Hit:5 http://ports.ubuntu.com/ubuntu-ports noble-security InRelease
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
39 packages can be upgraded. Run 'apt list --upgradable' to see them.
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
iputils-ping is already the newest version (3:20240117-1ubuntu0.1).
0 upgraded, 0 newly installed, 0 to remove and 39 not upgraded.
▶ ▶️ Installing QEMU (to be able to build for linux/amd64) 🛠️
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  qemu-user qemu-user-static
0 upgraded, 2 newly installed, 0 to remove and 39 not upgraded.
Need to get 28.8 MB of archives.
After this operation, 270 MB of additional disk space will be used.
Get:1 http://ports.ubuntu.com/ubuntu-ports noble-updates/universe arm64 qemu-user arm64 1:8.2.2+ds-0ubuntu1.10 [11.9 MB]
Get:2 http://ports.ubuntu.com/ubuntu-ports noble-updates/universe arm64 qemu-user-static arm64 1:8.2.2+ds-0ubuntu1.10 [16.9 MB]
Fetched 28.8 MB in 3s (9055 kB/s)           
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package qemu-user.
(Reading database ... 17248 files and directories currently installed.)
Preparing to unpack .../qemu-user_1%3a8.2.2+ds-0ubuntu1.10_arm64.deb ...
Unpacking qemu-user (1:8.2.2+ds-0ubuntu1.10) ...
Selecting previously unselected package qemu-user-static.
Preparing to unpack .../qemu-user-static_1%3a8.2.2+ds-0ubuntu1.10_arm64.deb ...
Unpacking qemu-user-static (1:8.2.2+ds-0ubuntu1.10) ...
Setting up qemu-user-static (1:8.2.2+ds-0ubuntu1.10) ...
Setting up qemu-user (1:8.2.2+ds-0ubuntu1.10) ...
Processing triggers for systemd (255.4-1ubuntu8.10) ...
▶ Installing MetalLB...🚀
namespace/metallb-system created
customresourcedefinition.apiextensions.k8s.io/bfdprofiles.metallb.io created
customresourcedefinition.apiextensions.k8s.io/bgpadvertisements.metallb.io created
customresourcedefinition.apiextensions.k8s.io/bgppeers.metallb.io created
customresourcedefinition.apiextensions.k8s.io/communities.metallb.io created
customresourcedefinition.apiextensions.k8s.io/ipaddresspools.metallb.io created
customresourcedefinition.apiextensions.k8s.io/l2advertisements.metallb.io created
customresourcedefinition.apiextensions.k8s.io/servicel2statuses.metallb.io created
serviceaccount/controller created
serviceaccount/speaker created
role.rbac.authorization.k8s.io/controller created
role.rbac.authorization.k8s.io/pod-lister created
clusterrole.rbac.authorization.k8s.io/metallb-system:controller created
clusterrole.rbac.authorization.k8s.io/metallb-system:speaker created
rolebinding.rbac.authorization.k8s.io/controller created
rolebinding.rbac.authorization.k8s.io/pod-lister created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:controller created
clusterrolebinding.rbac.authorization.k8s.io/metallb-system:speaker created
configmap/metallb-excludel2 created
secret/metallb-webhook-cert created
service/metallb-webhook-service created
deployment.apps/controller created
daemonset.apps/speaker created
validatingwebhookconfiguration.admissionregistration.k8s.io/metallb-webhook-configuration created
▶ Waiting for MetalLB pods...⏳
pod/controller-86f5578878-bjqmd condition met
pod/speaker-gtw49 condition met
▶ Creating MetalLB config...🛠️
▶ Using MetalLB range: 172.18.0.200-172.18.0.250 🛠️
▶ Successfully reconfigured network prefix in /tmp/metallb-kind-config.yaml... ✅
▶ Applying MetalLB configuration...🚀
ipaddresspool.metallb.io/colima-kind-pool created
l2advertisement.metallb.io/empty created
▶ Deploying the test LoadBalancer service...🚀
pod/foo-app created
pod/bar-app created
service/foo-service created
▶ Waiting for the LoadBalancer service to be ready...⏳
▶ Waiting for the backend pods to be ready...⏳
pod/bar-app condition met
pod/foo-app condition met
▶ Finally, lets test MetalLB using a simple LoadBalancier service foo-service!... 🙂
▶ Checking that the LoadBalancer service obtained an ingress IP...👀
▶ LoadBalancer ingress IP: 172.18.0.200
bar-app foo-app bar-app foo-app foo-app foo-app foo-app bar-app bar-app foo-app
Test succeeded ✅
▶ Cleaning temporary configuration files: /tmp/metallb-kind-config.yaml /tmp/kind-single-node-config.yaml  ✨
