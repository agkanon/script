#!/bin/bash

# Remove any old versions

DEPLOY_DIR=deployment/insightdb
KUBECTL_LOCATION=/usr/local/bin/kubectl
K3D_LOCATION=/usr/local/bin/k3d

# echo "Removing................................. old packages"
# sudo yum -y remove docker docker-common docker-selinux docker-engine
# if [ $? -eq 0 ]; then
#    echo OLD Packages Removed
# else
#    echo FAIL 
#    exit 1
# fi

# Install required packages
echo "Installing................................Pre-requisite"
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 curl wget git

if [ $? -eq 0 ]; then
     echo “Success,  Pre-requisite installation Done”
else
     echo “Pre-requisite installation Failed, Please re-run this script again.”
     exit 1
fi

# Configure docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker-ce
echo "Installing ......................................DOCKER"
sudo yum install docker-ce -y
if [ $? -eq 0 ]; then
   echo "Docker Install.....................................Done"
else
   echo Docker installation Failed, Please re-run this script again. Thank You!!!! 
   exit 1
fi

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

echo "Installation  --------------------------------Complete"

# Download the latest release kubectl
echo "Download the latest release kubectl...................KUBECTL"
if [[ -f "$KUBECTL_LOCATION" ]]; then
    echo "kubectl already exists."
                else curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl &&
                echo "kubectl>>>>>>>>>Installation>>>>>>>>Done"
fi

# git clone 
echo "Cloning from git@gitlab.com:ops52/single-k8s-k3d-deployment.git"
rm -rf single-k8s-k3d-deployment/
if [ $? -eq 0 ]; then
         git clone git@gitlab.com:ops52/single-k8s-k3d-deployment.git &&
         cd single-k8s-k3d-deployment
         echo git Project cloning done
     else
          echo You have not proper permission for this Project, Please communicate with concern person.
   exit 1
fi


# Download the latest release K3D
echo "Download k3D binary x64..................................K3D"


if [[ -f "$K3D_LOCATION" ]]; then
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
   echo Please delete k3d insightdb-cluster
   k3d cluster delete insightdb-cluster
   echo Please, re-run this script again, Thank you!!!!! 
   exit 1
fi


echo "To check cluster Please hit another terminal .........."kubectl get no"..........."
kubectl get no

## Description: Set up MySQL Community Release 5.7

kubectl apply -f $DEPLOY_DIR/mysql_deployment.yaml 
if [ $? -eq 0 ]; then
   echo MYSQL Apply Done, Please wait or describe another terminal this pod 'kubectl describe po mysql'
else
   echo Please check status
   exit 1
fi
kubectl rollout status deployment mysql 
if [ $? -eq 0 ]; then
   echo deployment MYSQL successfully rolled out, Please go ahead
else
   echo Please wait or re-check image pulling situation or
   kubectl delete -f $DEPLOY_DIR/mysql_deployment.yaml 
   echo Please re-deploy again
   exit 1
fi

echo "MYSQL Deployment........................................ Complete"
echo "Plese execute 'kubectl get po -o wide', when pod is running state then execute 'kubectl exec --stdin --tty pod/{POD_NAME} -c mysql -- /bin/bash' then login mysql"

echo "Deploying...............................................NGINX POD "
kubectl create deployment nginx --image=nginx
if [ $? -eq 0 ]; then
   echo NGINX Apply Done, Please wait or describe another terminal this pod 'kubectl describe po nginx'
else
   echo Please describe the nginx deployment
   exit 1
fi
kubectl rollout status deployment nginx --timeout 120s
if [ $? -eq 0 ]; then
   echo deployment NGINX successfully rolled out, Please go ahead
else
   echo Please wait or re-check image pulling situation.
   exit 1
fi
echo "Creating...............................................NGINX Service"
kubectl create service clusterip nginx --tcp=80:80
if [ $? -eq 0 ]; then
   echo NGINX service Done, Please go ahead
else
   echo Please check status
   exit 1
fi

kubectl apply -f $DEPLOY_DIR/ingress.yaml
if [ $? -eq 0 ]; then
   echo ingress Deployment Done, Please go ahead
else
   echo Please check status
   exit 1
fi
echo "Please hit---------------- 'curl localhost:8081/' on your browser"
echo "Installation------------------------------------------- Complete"
