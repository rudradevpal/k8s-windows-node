# Setup Windows Minion with Kubernetes
From Kubernetes 1.14 release kubernetes has came up with support of Windows minion/worker nodes. So if you are using kubernetes version 1.14 or later you will be able to setup windows minion with your existing cluster and can orchestrate windows based containers with kubernetes.
But before proceeding further make sure to go through below considerations.

## Consideration
1. Kubernetes version should be 1.14 or later
2. There is some limitation on CNI plugin. Until now windows only supports
   * Flannel (vxlan or host-gw) cluster.
   * With a ToR switch.
3. As we will label the node we have to use node selector to deploy windows based container on that node.

## Steps
### Deploy Kubernetes Control Plane
I am using `Ubuntu 18.04` as Master Node. The scripts will not work for other distributions of linux.
* Install Docker and Enable Docker
    ```shell
     ./install_docker.sh
    ```
	
* Install kubeletk, kubeadm and kubectl
    ```shell
    ./install_kubeadm.sh
    ```

* Deploy kubernetes
    ```shell
    ./deploy_k8s.sh 
    ```
  
* Install CNI as Flannel
    ```shell
    kubectl create -f kube-flannel.yaml
    ```

###  Enable Mixed Scheduling
* On Master Node execute
    ```shell
    cd ~ && mkdir -p k8s/yaml && cd k8s/yaml
    ```
  
* Check `kube-proxy` DaemonSet is set to RollingUpdate
    ```shell
    kubectl get ds/kube-proxy -o go-template='{{.spec.updateStrategy.type}}{{"\n"}}' --namespace=kube-system
    ```
  
* Download node-selector-patch
    ```shell
    wget https://raw.githubusercontent.com/Microsoft/SDN/master/Kubernetes/flannel/l2bridge/manifests/node-selector-patch.yml
    ```
  
* Patch `kube-proxy` with the downloaded one
    ```shell
    kubectl patch ds/kube-proxy --patch "$(cat node-selector-patch.yml)" -n=kube-system
    ```
  
* Check `kube-proxy` status
    ```shell
    kubectl get ds -n kube-system
    ```
  
* Download node-selector-patch
    ```shell
    wget https://raw.githubusercontent.com/Microsoft/SDN/master/Kubernetes/flannel/l2bridge/manifests/node-selector-patch.yml
    ```

###  Modify Flannel Networking
Follow the below step if you already have flannel on your cluster. If you have deployed through `kube-flannel-mod.yml` from this repo skip 1 to 3.
1. Change flannel ConfigMap
    ```shell
    kubectl edit cm -n kube-system kube-flannel-cfg
    ```
  
2. Edit `cni-conf.json` section like below
    ```yaml
    cni-conf.json: |
    {
      "name": "vxlan0",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
    ```
  
3. Also modify `net-conf.json` section like below
    ```yaml
    net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan",
        "VNI" : 4096,
        "Port": 4789
      }
    }
    ```
  *Check and put your `pod-cidr` in `Network` section*
  
4. Patch `kube-flannel`
    ```shell
    kubectl patch ds/kube-flannel-ds-amd64 --patch "$(cat node-selector-patch.yml)" -n=kube-system
    ```

###  Windows minion preparation
I am using `Windows Server 2019 with Desktop Environment x64`. All the below commands will be executed on `powershell`.
* Install Docker on Windows Node
    ```bat
    Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
    Install-Package -Name Docker -ProviderName DockerMsftProvider
    Restart-Computer -Force
    ```

* Start Docker
    ```bat
    Start-Service docker
    ```

* Create directory for kubernetes
    ```bat
    mkdir C:\kube; cd C:\kube
    ```
  
* Download and stage Kubernetes packages. Download [kubernetes-node-windows-amd64](https://dl.k8s.io/v1.15.6/kubernetes-node-windows-amd64.tar.gz). Extract and Find `kubeadm`, `kubectl`, `kubelet`, and `kube-proxy` put all the files in `C:\kube`.

* Copy Kubernetes certificate file from master node(From `~/.kube/config`) to `C:\kube` directory.

* Add paths to environment variables
    ```bat
    $env:Path += ";C:\kube"; $env:KUBECONFIG="C:\kube\config"; [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\kube", [EnvironmentVariableTarget]::Machine); [Environment]::SetEnvironmentVariable("KUBECONFIG", "C:\kube\config", [EnvironmentVariableTarget]::User)
    ```

###  Joining Windows Minion to Master
I am using `Windows Server 2019 with Desktop Environment x64`. All the below commands will be executed on `powershell`.
* Download Script
    ```bat
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    wget https://raw.githubusercontent.com/Microsoft/SDN/master/Kubernetes/flannel/start.ps1 -o c:\k\start.ps1
    ```

* Go to `C:\kube`
    ```bat
    cd C:\kube
    ```

* Join Flannel Cluster. Replace `IP_OF_WINDOWS_NODE` with node IP.
    ```bat
    .\start.ps1 -ManagementIP <IP_OF_WINDOWS_NODE> -NetworkMode overlay -InterfaceName Ethernet -Verbose

###  Test Windows Node
* Get YAML
    ```shell
    wget https://raw.githubusercontent.com/Microsoft/SDN/master/Kubernetes/flannel/l2bridge/manifests/simpleweb.yml -O win-webserver.yaml
    ```

* Deploy on K8s
    ```shell
    kubectl apply -f .\win-webserver.yaml
    ```

* Check Status
    ```shell
    kubectl get pods -o wide -w
    ```
