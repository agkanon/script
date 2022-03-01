#!/bin/bash

# Remove any old versions

DEPLOY_DIR=deployment/insightdb
kubectl=/usr/local/bin/kubectl
helm=/usr/local/bin/helm
k3d=/usr/local/bin/k3d

echo "Removing................................. old packages"
sudo yum -y remove docker docker-common docker-selinux docker-engine
if [ $? -eq 0 ]; then
   echo OLD Packages Removed
else
   echo FAIL exit status: $?
fi

# Install required packages
echo "Installing................................Pre-requisite"
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 curl wget git

if [ $? -eq 0 ]; then
     echo “Success,  Pre-requisite installation Done”
else
     echo “Failed, Please check your internet connection. exit status: $?”
fi

# Configure docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker-ce
echo "Installing ......................................DOCKER"
sudo yum install docker-ce -y
if [ $? -eq 0 ]; then
   echo "Docker Install.....................................Done"
else
   echo Please check your internet connectivity 
fi

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

echo "Installation  --------------------------------Complete"

# Download the latest release kubectl
echo "Download the latest release kubectl...................KUBECTL"
if [[ -f "$kubectl" ]]; then
    echo "$kubectl already exists."
                else curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl &&
                echo "kubectl>>>>>>>>>Installation>>>>>>>>Done"
fi

# Description: Install helm
if [[ -f "$helm" ]]; then
    echo "$helm already exists."
                else wget https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz &&
                tar -xvf helm-v3.6.3-linux-amd64.tar.gz &&
                mv linux-amd64/helm /usr/local/bin/helm &&
                echo "helm >>>>>>>>Installation>>>>>>>>>> Done" &&
                helm version
fi

# Add Repo
echo "Adding.....................................HELM STABLE REPO"
helm repo add stable https://charts.helm.sh/stable && 
helm repo add kong https://charts.konghq.com &&
helm repo update

# git clone 
echo "Cloning from git@gitlab.com:ops52/single-k8s-k3d-deployment.git"
git clone git@gitlab.com:ops52/single-k8s-k3d-deployment.git && cd single-k8s-k3d-deployment
if [ $? -eq 0 ]; then
         echo git Project cloning done
else
   echo exit, Please Create proper authentication.
fi


# Download the latest release K3D
echo "Download k3D binary x64..................................K3D"

k3d=/usr/local/bin/k3d
if [[ -f "$k3d" ]]; then
    echo "k3d already exists."
                else curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
                echo "k3d>>>>>>>>>Installation>>>>>>>>Done"
fi

echo "K3D Installation......................................... Done"

#Create K3D cluster
echo "k3d cluster create using--------config-file"
k3d cluster create --config $DEPLOY_DIR/config.yaml
if [ $? -eq 0 ]; then
   echo k3d cluster creation done
else
   echo Please check status
fi


echo "To check cluster Please hit .........."kubectl get no"..........."
kubectl get no

## Description: Set up MySQL Community Release 5.7

kubectl apply -f $DEPLOY_DIR/mysql_deployment.yaml 
if [ $? -eq 0 ]; then
   echo MYSQL Deployment Done, Please wait
else
   echo Please check status
fi
kubectl rollout status deployment mysql --timeout 180s
if [ $? -eq 0 ]; then
   echo MYSQL rollout Done, Please go ahead
else
   echo Please wait or re-check image pulling situation.
fi

echo "MYSQL Deployment........................................ Complete"
echo "Plese execute 'kubectl get po -o wide', when pod is running state then execute 'kubectl exec --stdin --tty pod/{POD_NAME} -c mysql -- /bin/bash' then login mysql"

echo "Deploying...............................................NGINX POD "
kubectl create deployment nginx --image=nginx
if [ $? -eq 0 ]; then
   echo NGINX Deployment Done, Please wait
else
   echo Please check status
fi
kubectl rollout status deployment nginx --timeout 120s
if [ $? -eq 0 ]; then
   echo NGINX rollout Done, Please go ahead
else
   echo Please wait or re-check image pulling situation.
fi
echo "Creating...............................................NGINX Service"
kubectl create service clusterip nginx --tcp=80:80
if [ $? -eq 0 ]; then
   echo NGINX service Done, Please go ahead
else
   echo Please check status
fi

kubectl apply -f $DEPLOY_DIR/ingress.yaml
if [ $? -eq 0 ]; then
   echo ingress Deployment Done, Please go ahead
else
   echo Please check status
fi
echo "Please hit---------------- 'curl localhost:8081/' on your browser"
echo "Installation------------------------------------------- Complete"
