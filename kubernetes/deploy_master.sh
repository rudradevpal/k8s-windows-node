set -e
echo "Turning swap off..."
sudo swapoff -a
# sudo mount bpffs /sys/fs/bpf -t bpf
echo "Starting Kubernetes..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/24

echo "Setting kubeconfig..."
mkdir -p $HOME/.kube
sudo -H cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo -H chown $(id -u):$(id -g) $HOME/.kube/config
