# sudo vi /etc/netplan/*****.yaml
network:
  ethernets:
    enp0s3:
      addresses: [192.168.1.240/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [*****, ****]
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
192.168.1.240 k8s-master
192.168.1.241 k8s-node1
192.168.1.242 k8s-node2
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

apt update
apt install -y kubelet kubeadm kubectl

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

kubeadm init --pod-network-cidr=20.96.0.0/12 --apiserver-advertise-address=192.168.1.240

# node에만 실행
kubeadm join 192.168.1.240:6443 --token gu5s1v.18p8fhrajc1v3qyu \
	--discovery-token-ca-cert-hash sha256:fa13df9297a08c91499b0eaf9179b6e3864170607f1e19c50b2ad814e252f5fd

# 다시 마스터만 실행
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

curl -O https://projectcalico.docs.tigera.io/v3.19/manifests/calico.yaml
sed s/192.168.0.0\\/16/20.96.0.0\\/12/g -i calico.yaml
kubectl apply -f calico.yaml

# 대쉬보드 설치
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml

nohup kubectl proxy --port=8001 --address=192.168.1.240 --accept-hosts='^*$' >/dev/null 2>&1 &

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

# 대쉬보드 외부 접속 방법(type을 nodeport로 변경)
kubectl -n kubernetes-dashboard edit service kubernetes-dashboard

# nodeport 확인
kubectl -n kubernetes-dashboard get service kubernetes-dashboard 

# https로 접속
https://192.168.1.240:30886

# ServiceAccount, ClusterRoleBinding, Secret 생성
kubectl apply -f dashboard-user.yaml

# token 확인
kubectl describe secret default-token -n kubernetes-dashboard

# token 제한시간 무제한
kubectl edit -n kubernetes-dashboard deployments.apps kubernetes-dashboard

# ... content before...

    spec:
      containers:
      - args:
        - --auto-generate-certificates
        - --namespace=kubernetes-dashboard
        - --token-ttl=0 # <-- 이걸 추가
      image: kubernetesui/dashboard:v2.6.0

# ... content after ...