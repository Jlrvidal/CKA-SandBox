#!/bin/bash

# Read the IP addresses from the configuration file
source /vagrant/ip_config.txt

# Install net-tools
sudo apt-get install net-tools

# Install etcdctl for managing etcd
# ETCD_VERSION=v3.4.13
# ETCD_ARCH=etcd-${ETCD_VERSION}-linux-amd64
# curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/${ETCD_ARCH}.tar.gz -o /tmp/etcd.tar.gz
# tar xzvf /tmp/etcd.tar.gz -C /usr/local/bin --strip-components=1 ${ETCD_ARCH}/etcdctl

# Install autocompletion for kubectl and bash
sudo apt-get install bash-completion
echo 'source <(kubectl completion bash)' >>/home/vagrant/.bashrc
echo 'alias k=kubectl' >>/home/vagrant/.bashrc
echo 'complete -F __start_kubectl k' >>/home/vagrant/.bashrc
source /home/vagrant/.bashrc


# Install Helm for package management
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Kubernetes Dashboard 
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

# Install a configure ingress-nginx. This is an Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/cloud/deploy.yaml

# kubectl create deployment httpd --image=httpd --port=80
# kubectl expose deployment httpd

# kubectl create ingress demo-localhost --class=nginx --rule="dashboard.local/*=demo:80"

# kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80

# curl --resolve dashboard.local:8080:127.0.0.1 http://dashboard.local:8080

# NGINX_PORT=$(kubectl get service nginx -o=jsonpath='{.spec.ports[0].nodePort}')
# # Function to find the IP matching the 192.168.56.x subnet
# get_matching_ip() {
#     ip --json addr show | jq -r '.[] | .addr_info[] | select(.family == "inet") | .local' | grep "^${NETWORK_IP}\." | head -n 1
# }

# # Get the IP address that matches the subnet
# VM_IP=$(get_matching_ip)

# # Check if a matching IP was found
# if [ -z "$VM_IP" ]; then
#     echo "No matching IP found in the 192.168.56.x subnet."
#     exit 1
# fi

# echo "=================================================="
# echo "NGINX is deployed on your Kubernetes cluster!"
# echo "You can access it from your Windows browser at: http://$VM_IP:$NGINX_PORT"
# echo "=================================================="