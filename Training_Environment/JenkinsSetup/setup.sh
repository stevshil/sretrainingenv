#!/bin/bash

# New configuration
restart=0

echo "Getting IP address"
USEIP=$(ip a | egrep -A1 '(enp0s3|eth0)' | grep inet | awk '{print $2}' | sed 's,/.*$,,')
if [[ -z $USEIP ]]
then
    echo "NO IP ADDRESS FOUND"
    echo -n "Please enter your VM IP address: "
    read USEIP
fi

echo "[CHECK] if we need to install Docker"
if ! dpkg -l | grep docker.io >/dev/null 2>&1
then
    echo "[INSTALL] Docker"
    sudo apt update
    sudo apt -y upgrade
    sudo apt -y install docker.io
fi

echo "[CHECK] if we need to add $LOGNAME to /etc/group for Docker"
if ! grep docker /etc/group | grep $LOGNAME >/dev/null 2>&1
then
    echo "[INSTALL] $LOGNAME to /etc/group for Docker"
    sudo usermod -aG docker ${LOGNAME}
fi

echo "[CHECK] if kubectl is installed"
if [[ ! -e /usr/local/bin/kubectl ]]
then
    echo "[INSTALL] kubectl"
    sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install kubectl /usr/local/bin/kubectl
fi

echo "[CHECK] if minikube is installed"
if [[ ! -e /usr/local/bin/minikube ]]
then
    echo "[INSTALL] minikube"
    sudo curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    install minikube-linux-amd64 /usr/local/bin/minikube
fi

# Image registry proxy error
# --image-repository auto  # currently trying
# or
# --docker-env HTTP_PROXY=https://minikube.sigs.k8s.io/docs/reference/networking/proxy/
# or
# --image-mirror-country=cn \ 
#   --registry-mirror=https://registry.docker-cn.com \ 
#   --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers

# NO PROXY - address ranges used by kubernetes cluster in minikube
# export NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.59.0/24,192.168.49.0/24,192.168.39.0/24

echo "[START] minikube"
if ! minikube start --cpus 2 --memory 4g --driver docker
then
    if ! ps -ef | grep minikube | grep kube-apiserver >/dev/null 2>&1
    then
        echo "[RESTART] minikube"
        minikube start
        restart=1
    else
        echo "[OK] minkube already running"
    fi
fi

echo "[START] minikube ingress"
if ! minikube addons enable ingress
then
    echo "[FAILED] ingress did not complete"
    exit 1
fi

# echo "[APPLY] tekton"
# kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

echo "[CREATE] Jenkins kubeconfig"
# Add the .kube/config to a ConfigMap
cp $HOME/.kube/config /tmp/kubeconfig
sed -i 's,/home/k8s/.minikube,/var/jenkins_home/.kube,' /tmp/kubeconfig
sed -i 's,profiles/minikube,,' /tmp/kubeconfig
sed -i 's,//,/,' /tmp/kubeconfig

echo "[WAITING] for Kubernetes to be ready"
while [[ ! -e $HOME/.minikube/profiles/minikube/client.key ]]
do
    sleep 5
done

echo "[CREATE] Jenkins namespace"
kubectl apply -f namespace.yaml
echo "[CREATE] Jenkins kube certs"
kubectl create configmap kubeconfig -n jenkins \
    --from-file=/tmp/kubeconfig \
    --from-file=$HOME/.minikube/profiles/minikube/client.crt \
    --from-file=$HOME/.minikube/profiles/minikube/client.key \
    --from-file=$HOME/.minikube/ca.crt

# Create casc.yaml for Jenkins initial load
kubectl create configmap casc -n jenkins \
    --from-file=configfiles/casc.yaml
kubectl create configmap refs -n jenkins \
    --from-file=configfiles/seedjob.groovy

echo "[START] tunnel"
nohup minikube tunnel --bind-address=${USEIP} &

if (( restart == 0 ))
then
    echo "[START] Jenkins"
    for item in jenkinspv.yaml jenkins.yaml jenkinssvc.yaml
    do
        kubectl apply -f ${item}
    done
fi