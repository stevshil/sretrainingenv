#!/bin/bash

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

echo "[START] minikube"
if ! minikube start --cpus 2 --memory 4g --driver docker
then
    if ! ps -ef | grep minikube | grep kube-apiserver >/dev/null 2>&1
    then
        echo "[RESTART] minikube"
        minikube start
    else
        echo "[OK] minkube already running"
    fi
fi

echo "[CHECKING] ingress"
if minikube addons list | grep ingress | grep enabled >/dev/null 2>&1
then
    echo "[OK] ingress already active"
else
    echo "[START] minikube ingress"
    if ! minikube addons enable ingress
    then
        echo "[FAILED] ingress did not complete"
        exit 1
    fi
fi

if [[ ! -e /usr/sbin/helm ]]
then
    echo "[INSTALL] Helm"
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    sudo apt-get install apt-transport-https --yes
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm
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

echo "[CHECK] Jenkins namespace"
if ! (kubectl get ns | grep jenkins) >/dev/null 2>&1
then
    echo "[CREATE] Jenkins namespace"
    kubectl apply -f namespace.yaml
fi

echo "[CHECK] Jenkins ConfigMaps"
if ! (kubectl get configmap -n jenkins | grep kubeconfig) >/dev/null 2>&1
then
    echo "[CREATE] Jenkins kube certs"
    kubectl create configmap kubeconfig -n jenkins \
        --from-file=/tmp/kubeconfig \
        --from-file=$HOME/.minikube/profiles/minikube/client.crt \
        --from-file=$HOME/.minikube/profiles/minikube/client.key \
        --from-file=$HOME/.minikube/ca.crt
fi

if ! (kubectl get configmap -n jenkins | grep casc) >/dev/null 2>&1
then
    # Create casc.yaml for Jenkins initial load
    kubectl create configmap casc -n jenkins \
        --from-file=configfiles/casc.yaml
fi
if ! (kubectl get configmap -n jenkins | grep refs) >/dev/null 2>&1
then
    kubectl create configmap refs -n jenkins \
        --from-file=configfiles/seedjob.groovy
fi

echo "[START] tunnel"
nohup minikube tunnel --bind-address=${USEIP} &

echo "[CHECK] Jenkins"
if ! ( kubectl get all -n jenkins | grep deployment ) >/dev/null 2>&1
then
    echo "[START] Jenkins"
    for item in jenkinspv.yaml jenkins.yaml jenkinssvc.yaml
    do
        kubectl apply -f ${item}
    done
else
    echo "[OK] Jenkins configured already"
fi

# Docker registry using Helm
# https://guide.opencord.org/cord-6.0/prereqs/docker-registry.html
# https://www.paulsblog.dev/how-to-install-a-private-docker-container-registry-in-kubernetes/

echo "[CHECK] Docker certs"
if ! (kubectl get configmap -n docker-registry | grep regcerts) >/dev/null 2>&1
then
    echo "[CREATING] Docker SSL certs"
    openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 36500 -out domain.crt -subj "/C=UK/ST=Kent/L=Medway/O=TPS Services Ltd/CN=*/OU=docker"
    echo "[CREATE] Docker Registry certs"
    kubectl create configmap regcerts -n docker-registry \
        --from-file=domain.key \
        --from-file=domain.crt
fi

echo "[CHECK] Docker Registry"
if ! (kubectl get pvc -n docker-registry | grep registry-pvc) >/dev/null 2>&1
then
    echo "[CREATING] Docker Registry store"
    kubectl apply -f registry-pvc.yaml
fi
if ! (kubectl get all -n docker-registry | grep pod | grep Running) >/dev/null 2>&1
then
    echo "[CREATING] Docker Registry"
    kubectl apply -f registry.yaml
fi

# Password for registry is secret123
# echo "[INSTALL] Helm repository"
# helm repo add twuni https://helm.twun.io
# echo "[INSTALL] Docker Registry"
# helm install -f registry-chart.yaml docker-registry --namespace docker-registry twuni/docker-registry
