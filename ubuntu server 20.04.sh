# sudo vi /etc/netplan/*****.yaml
network:
  ethernets:
    enp0s3:
      addresses: [192.168.0.10/24]
      gateway4: 192.168.0.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
  version: 2

# 적용
netplan apply

sudo passwd root

sudo apt-get update

sudo apt upgrade


sudo apt-get install -y ntp

sudo systemctl start ntp

ntpq -p

sudo timedatectl set-timezone Asia/Seoul



sudo apt install net-tools

# openssh 설치
sudo apt install openssh-server

# 도커 설치
curl -s https://get.docker.com/ | sudo sh

sudo usermod -aG docker oracle

# 방화벽 해제
systemctl stop firewalld && systemctl disable firewalld

# Swap 비활성화
swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab

# 계획된 ip 등록
cat << EOF >> /etc/hosts
192.168.10.250 k8s-master
192.168.10.251 k8s-node1
192.168.10.252 k8s-node2
EOF

cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# 쿠버네티스 래파지토리 추가
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 도커 GPG key 추가
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

apt-get update
apt-get install -y kubelet kubeadm kubectl

mkdir /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

systemctl daemon-reload
systemctl enable --now docker
systemctl enable --now kubelet

# Error containerd
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

kubeadm init --pod-network-cidr=20.96.0.0/12 --apiserver-advertise-address=192.168.10.250