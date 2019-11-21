# Setup Windows Minion with Kubernetes
From Kubernetes 1.14 release kubernetes has came up with support of Windows minion/worker nodes. So if you are using kubernetes version 1.14 or later you will be able to setup windows minion with your existing cluster and can orchestrate windows based containers with kubernetes.
But before proceeding further make sure to go through below considerations.

## Consideration
1. Kubernetes version should be 1.14 or later
2. There is some limitation on CNI plugin. Until now windows only supports
   * Flannel (vxlan or host-gw) cluster.
   * With a ToR switch.
3. As we will label the node we have to use node selector to deploy windows based container on that node 

