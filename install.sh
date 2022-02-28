#!/bin/bash
# Install docker in centos

# Remove any old versions

DEPLOY_DIR=deployment/insightdb

echo "Removing................................. old packages"
sudo yum -y remove docker docker-common docker-selinux docker-engine

# Install required packages
echo "Installing................................Pre-requisite"
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 curl wget

# Configure docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker-ce
echo "Installing ......................................DOCKER"
sudo yum install docker-ce -y
echo "Docker Install.....................................Done"
# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

echo "Installation Complete ------------- Logout and Log back"

# Description: Install helm
# Step 1: Download Helm.
echo "Downloding........................................ HELM"
wget https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz

# Step 2: Extract Helm 
echo "Extracting........................................ HELM"
tar -xvf helm-v3.6.3-linux-amd64.tar.gz

# Step 3: Move Binary 
echo "Moving..............................................HELM"
mv linux-amd64/helm /usr/local/bin/helm

#Step 5: Check Helm Version
echo "Checking..........................................Version"
helm version

#Step 6: Add Repo
echo "Adding.....................................HELM STABLE REPO"
helm repo add stable https://charts.helm.sh/stable

## Install kong
echo "Adding ..........................................KONG REPO"
helm repo add kong https://charts.konghq.com
helm repo update

## Download k3d in centos
echo "Delete OLD cluster --------------k3d cluster delete my-cluster"
k3d cluster delete my-cluster
echo "Removing.............................................OLD K3D"
rm -rf /usr/local/bin/k3d

# Download the latest release kubectl
echo "Download the latest release kubectl...................KUBECTL"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

echo "Install the latest release kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Download the latest release K3D
echo "Download k3D binary x64..................................K3D"
echo "curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "K3D Installation......................................... Done"

#Create K3D cluster
echo "k3d cluster create using--------config-file"
k3d cluster create --config $DEPLOY_DIR/config.yaml

echo "To check cluster Please hit .........."kubectl get no"..........."
kubectl get no

## Description: Set up MySQL Community Release 5.7

kubectl apply -f $DEPLOY_DIR/mysql_deployment.yaml 
kubectl rollout status deployment mysql --timeout 180s

echo "MYSQL Deployment........................................ Complete"
echo "Plese execute 'kubectl get po -o wide', when pod is running state then execute 'kubectl exec --stdin --tty pod/{POD_NAME} -c mysql -- /bin/bash' then login mysql"

echo "Deploying...............................................NGINX POD "
kubectl create deployment nginx --image=nginx
kubectl rollout status deployment nginx --timeout 120s
echo "Creating...............................................NGINX Service"
kubectl create service clusterip nginx --tcp=80:80

kubectl apply -f $DEPLOY_DIR/ingress.yaml
echo "Please hit---------------- 'curl localhost:8081/' on your browser"
echo "Installation------------------------------------------- Complete"