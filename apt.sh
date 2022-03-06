#!/bin/bash

# Environmemt
TEMP_DIR=$(mktemp -d)
DEPLOY_DIR=deployment/insightdb
KUBECTL_LOCATION=/usr/local/bin/kubectl
K3D_LOCATION=/usr/local/bin/k3d
YUM_CMD=$(which yum)
APT_GET_CMD=$(which apt-get)
YUM_PACKAGE_NAME="yum-utils device-mapper-persistent-data lvm2 curl wget git"
DEB_PACKAGE_NAME="apt-transport-https ca-certificates curl software-properties-common"

installing_Pre_requisite() {
echo "Installing................................Pre-requisite"
if [[ ! -z $YUM_CMD ]]; then
    yum -y install $YUM_PACKAGE_NAME
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install docker-ce -y
         if [ $? -eq 0 ]; then
            echo "Docker Install.....................................Done"
            sudo systemctl start docker
            sudo systemctl enable docker
         else
            echo Docker installation Failed, Please re-run this script again. Thank You!!!! 
   exit 1
fi
 elif [[ ! -z $APT_GET_CMD ]]; then
    apt install $DEB_PACKAGE_NAME
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    apt-cache policy docker-ce
    sudo apt install docker-ce
    sudo systemctl status docker
else
    echo "error can't install package $PACKAGE"
    exit 1;
 fi

if [ $? -eq 0 ]; then
     echo “Success,  Pre-requisite installation Done”
else
     echo “Pre-requisite installation Failed, Please re-run this script again.”
     exit 1
fi
} 

# Download the latest release kubectl
install_kubectl() {
echo "Download the latest release kubectl...................KUBECTL"
if [[ -f "$KUBECTL_LOCATION" ]]; then
    echo "kubectl already exists."
                else curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl &&
                echo "kubectl>>>>>>>>>Installation>>>>>>>>Done"
fi
}

install_k3d() {
# Download the latest release K3D
echo "Download k3D binary x64..................................K3D"


if [[ -f "$K3D_LOCATION" ]]; then
    echo "k3d already exists."
                else curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
                echo "k3d>>>>>>>>>Installation>>>>>>>>Done"
fi

echo "K3D Installation......................................... Done"
}

git_cloning() {
echo "Cloning from git@gitlab.com:ops52/single-k8s-k3d-deployment.git"
rm -rf single-k8s-k3d-deployment/
if [ $? -eq 0 ]; then
         git clone git@gitlab.com:ops52/single-k8s-k3d-deployment.git
        if [ $? -eq 0 ]; then
        cd single-k8s-k3d-deployment
        echo git Project cloning done 
     else
          echo You have not proper permission for this Project, Please communicate with concern person.
   exit 1
fi

fi
}


cluster_deployment() {
#Create K3D cluster
cat <<EOF > $TEMP_DIR/config.yaml
apiVersion: k3d.io/v1alpha4
kind: Simple
metadata:
 name: my-cluster
agents: 0
kubeAPI: 
  hostPort: "6550" 
image: rancher/k3s:v1.22.6-k3s1 
ports:
  - port: 8081:80
    nodeFilters:
      - loadbalancer
EOF

echo "k3d cluster create using--------config-file"
k3d cluster create --config $TEMP_DIR/config.yaml
# echo "k3d cluster create using--------config-file"
# k3d cluster create --config $DEPLOY_DIR/config.yaml
if [ $? -eq 0 ]; then
   echo k3d cluster creation done
else
   echo Please delete k3d my-cluster
   k3d cluster delete my-cluster
   echo Please, re-run this script again, Thank you!!!!! 
   exit 1
fi

echo "To check cluster Please hit another terminal .........."kubectl get no"..........."
kubectl get no
}

mysql_deployment() {
# Description: Set up MySQL Community Release 5.7
echo "MYSQL Deployment File ....................................................executing..."
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
}

nginx_deployment() {
echo "Deploying...............................................NGINX POD "
kubectl create deployment nginx --image=nginx
if [ $? -eq 0 ]; then
   echo NGINX Apply Done, Please wait or describe another terminal this pod 'kubectl describe po nginx'
else
   echo Please describe the nginx deployment
   exit 1
fi
kubectl rollout status deployment nginx 
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
}

ingress_deployment() {

cat <<EOF > $TEMP_DIR/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
EOF






kubectl apply -f $TEMP_DIR/ingress.yaml

#kubectl apply -f $DEPLOY_DIR/ingress.yaml
if [ $? -eq 0 ]; then
   echo ingress Deployment Done, Please go ahead
else
   echo Please check status
   exit 1
fi

echo "Please hit---------------- 'curl localhost:8081/' on your browser"
echo "Installation------------------------------------------- Complete"
}


#installing_Pre_requisite
#install_kubectl
#install_k3d
git_cloning
#cluster_deployment
#mysql_deployment
nginx_deployment
ingress_deployment
