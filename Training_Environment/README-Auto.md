# Setting up the training environment (Automated)

This is the easier way to install the training environment.

You will need a virtual machine running Ubuntu, or Debian before continuing this option.

## Prerequisites

- Create a user called **k8s** or **sre**
- Copy the following folders onto your VM
  - Training_Enviornment/JenkinsSetup
    - Contains the shell script **setup.sh** that will install and run the Kubernetes system
    - Contains the YAML files used by the **setup.sh** script to launch the Jenkins service in Kubernetes and configures it ready for K8s
- Make the **setup.sh** file executable
- Make sure that the user that will be running the **setup.sh** script has **sudo** rights without needing a **password**

We use a specific Jenkins Docker image that has been pre-configured to work with Kubernetes and perform Docker-in-Docker builds.  The Docker image also contains an example job.  Container = **steve353/jenkins:k8s-v0.2**.

**IMPORTANT**: you will need **sudo** access as the script requires you to install software and configure user groups.

## Running the Environment

Change into the **JenkinsSetup** directory.

Run the command:

```
./setup.sh
```

This will require you to provide **sudo** password if your **sudo** has been set up to require passwords for the current user.

## Accessing Ingress Externally

The script attempts to detect your NIC very early in the start up.  If your interface is not enp0s3 or eth0 you will be prompted to enter the interface name.  You can find you NIC by running **ip a**.

Below is an example of running **ip a** and showing our NIC.

```bash
# Get the IP address of your VM
$ ip a  # Make sure you get the physical interface IP
...
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:a4:1f:29 brd ff:ff:ff:ff:ff:ff
    inet 192.168.58.27/24 brd 192.168.58.255 scope global dynamic noprefixroute enp0s3
...
```

You should now be able to point your web browser at http://192.168.58.27:8080, or whatever the VMs real IP address is (replace 192.168.58.27 with the IP address you found in the ip a command).

This will be useful where you don't have a GUI running.

## Final Jenkins information

You can find the ingress address of Minikube by running the following command:

```bash
$ minikube service list
|---------------|------------------------------------|--------------|---------------------------|
|   NAMESPACE   |                NAME                | TARGET PORT  |            URL            |
|---------------|------------------------------------|--------------|---------------------------|
| default       | kubernetes                         | No node port |                           |
| ingress-nginx | ingress-nginx-controller           | http/80      | http://192.168.49.2:32035 |
|               |                                    | https/443    | http://192.168.49.2:30938 |
| ingress-nginx | ingress-nginx-controller-admission | No node port |                           |
| jenkins          | jenkins                            |         8080 | http://192.168.49.2:30000 |
| kube-system   | kube-dns                           | No node port |                           |
|---------------|------------------------------------|--------------|---------------------------|
```

In the above we can see the command ran, and that our Jenkins system is using **http://192.168.49.2:30000**.

If you are running Minikube on a GUI version of Linux you can open this link in the web browser.

# Rebuilding Jenkins

To restart Jenkins to change the CASC configuration you will need to be in the JenkinsSetup folder, and perform the following;

1. Remove Jenkins
    ```
    kubectl delete -f jenkins.yaml
    ```
2. Remove the persistent storage
    ```
    kubectl delete -f jenkinspv.yaml
    ```
3. Run the setup.sh script to rebuild Jenkins with changes
    ```
    ./setup.sh
    ```

# Debugging

The ingress stage may fail with

```
❌  Exiting due to MK_ADDON_ENABLE: enable failed: run callbacks: running callbacks: [waiting for app.kubernetes.io/name=ingress-nginx pods: timed out waiting for the condition]
```

If it does use the following command;

```
kubectl get all -n ingress-nginx
```

Wait for
```
deployment.apps/ingress-nginx-controller   1/1     1            1           7m25s
```

And also the pod to be 1/1 Running.