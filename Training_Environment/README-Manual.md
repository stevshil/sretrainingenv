# Setting up the training environment (Manually)

The course is designed to run on a standalone Kubernetes infrastructure, allowing a student to run their own version, or to share in a team.

The system requires **MiniKube** and **Docker** to be installed on a Linux system.

Once **minikube** is started you can then deploy the environment using the **InitialSetup** folder which contains YAML files to install the necessary components.

## Installing MiniKube

Install Docker and MiniKube for Debian/Ubuntu

```bash
$ sudo apt update
$ sudo apt -y upgrade
$ sudo apt -y install docker.io
$ sudo usermod -aG docker <yourUserName>
$ curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
$ sudo install kubectl /usr/local/bin/kubectl
$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
$ sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

## Starting MiniKube

```bash
$ minikube start --cpus 2 --memory 4g # --driver docker
```

**NOTE:** You might have to change the **driver** depending on your virtual platform.

## Checking it works

```bash
$ kubectl get nodes
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   22m   v1.26.3
```

## Starting MiniKube after a reboot

Simply run the following:

```bash
$ minikube start
```

## To access applications

You only need to run this the once, unless you completely rebuild the minikube system.

To view web based applications within MiniKube you will need to run:

```bash
$ minikube addons enable ingress
* ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
  - Using image registry.k8s.io/ingress-nginx/controller:v1.7.0
  - Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20230312-helm-chart-4.5.2-28-g66a760794
  - Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v20230312-helm-chart-4.5.2-28-g66a760794
* Verifying ingress addon...
* The 'ingress' addon is enabled
```

This command runs a known YAML configuration to provide your system with an NGINX ingress proxy.  The process is complete when you see the **The 'ingress' addon is enabled**.

You can check the Ingress controller is there with:

```bash
$ minikube service list
|---------------|------------------------------------|--------------|---------------------------|
|   NAMESPACE   |                NAME                | TARGET PORT  |            URL            |
|---------------|------------------------------------|--------------|---------------------------|
| default       | kubernetes                         | No node port |                           |
| ingress-nginx | ingress-nginx-controller           | http/80      | http://192.168.49.2:32035 |
|               |                                    | https/443    | http://192.168.49.2:30938 |
| ingress-nginx | ingress-nginx-controller-admission | No node port |                           |
| kube-system   | kube-dns                           | No node port |                           |
|---------------|------------------------------------|--------------|---------------------------|
```

# Kubernetes Pipelines with Tekton

Rather than Jenkins pipelines, Kubernetes and OpenShift container platforms come with a new built-in pipeline system called Tekton.  To install it run:

```bash
$ kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
# Check that it installs
$ kubectl get pods --namespace tekton-pipelines --watch
......
tekton-pipelines-controller-6d989cc968-j57cs   1/1     Running             0          10s
tekton-pipelines-webhook-69744499d9-t58s5      1/1     Running             0
^C
```

# Jenkins installation

Reference - https://blog.thecloudside.com/docker-in-docker-with-jenkins-pod-on-kubernetes-f2b9877936f2. NOTE: This is only partially complete.

1. Change to the JenkinsSetup directory
2. Create the PV using:
    ```
    kubectl apply -f jenkinspv.yaml
    ```
3. Install Jenkins
    ```
    kubectl apply -f jenkins-manual.yaml
    ```
4. Create the services
    ```
    kubectl apply -f jenkinssvc.yaml
    ```
5. Log on to Jenkins, you'll need the access code from
    ```
    kubectl logs $(kubectl get all -n jenkins | grep pod | awk '{print $1}') -n jenkins
    ```
    NOTE: you can check progress and errors with:
    ```
    kubectl events -n jenkins
    ```
    This will help if there are any container image pull issues, etc.

Once Jenkins is installed use:

```bash
minikube service list
```

To get the URL and port number for the Jenkins service, which should look something like;
```
 jenkins          | jenkins                            |         8080 | http://192.168.49.2:30000
 ```

 NOTE: the http://192.168.49.2 may change based on your installation.  This is the address the the **minikube addons enable ingress** gives you.

### This is covered in teh bin/setup.sh and initialSetup/jenkins.yaml

You will need to copy your .kube/config file on to the Jenkins container:

```bash
kubectl exec -it -n jenkins jenkins-<podid> mkdir /var/jenkins_home/.kube
kubectl cp .kube/config jenkins-<podid>:/var/jenkins_home/.kube/config -n jenkins 
kubectl cp .minikube/ca.crt jenkins-<podid>:/var/jenkins_home/.kube/ca.crt -n jenkins
kubectl cp .minikube/profiles/minikube/client.crt jenkins-<podid>:/var/jenkins_home/.kube/client.crt -n jenkins
kubectl cp .minikube/profiles/minikube/client.key jenkins-<podid>:/var/jenkins_home/.kube/client.key -n jenkins
```

## Complete the Jenkins setup

Point your web browser on the VM to your Jenkins server on port 30000, and continue the setup, adding an **Admin** user with password **secret**.

You will need to install the **Kubernetes** cloud plugin.  Go to **Manage Jenkins** and **Plugin Manager**.  Select **Available** and type in **Cloud Providers** and select **Kubernetes**.  Click the **Install without restart** button.

You will also need:
- Kubernetes
- Kubernetes Credentials Plugin
- Kubernetes Client API Plugin
- Kubernetes :: Pipeline :: DevOps Steps
- Docker

Go to **Manage Jenkins** and select **Manage Nodes and Clouds**.  Click **Configure Clouds**.  Click **Add a new cloud** and select **Kubernetes**.  Set the **Kubernetes Namespace** as **jenkins**.

When Setting up the Cloud Provider for Kubernetes make sure you use **jenkins-jnlp:50000**. Ideally we would like to use the service name **jenkins-jnlp**, but sadly this fails with error about https, and **forbidden service account**.  So you will need the **ClusterIP** for the jenkins-jnlp service:

```bash
$ kubectl get svc/jenkins-jnlp -n jenkins
NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
jenkins-jnlp   ClusterIP   10.105.41.110   <none>        50000/TCP   30m
```

In the above case 10.105.41.110.


NOTE: If you need to view Jenkins then you will need to run the following command in the terminal on the **minikube** system:

```bash
# Get the IP address of your VM
$ ip a  # Make sure you get the physical interface IP
...
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:a4:1f:29 brd ff:ff:ff:ff:ff:ff
    inet 192.168.58.27/24 brd 192.168.58.255 scope global dynamic noprefixroute enp0s3
...
$ minikube tunnel --bind-address=192.168.58.27
```

NOTE: You have to leave this command running in a terminal.

You should now be able to point your web browser at http://192.168.58.27:8080, or whatever the VMs real IP address is (replace 192.168.58.27 with the IP address you found in the ip a command).

This will be useful where you don't have a GUI running.