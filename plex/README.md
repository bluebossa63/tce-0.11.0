for each node:
    sudo tdnf install nfs-utils

ubuntu:
    sudo apt install nfs-kernel-server
    sudo mkdir /exports
    sudo chmod 777 exports
    sudo echo "/exports *(rw,sync,no_subtree_check) >> /etc/exports
    sudo sudo ufw allow from 0.0.0.0/0 to any port nfs
    sudo systemctl enable nfs-server && systemctl start nfs-server

kubectl apply -f plex-tls-cert-certificate.yaml
kubectl apply -f plex/nfs-volume.yaml
kubectl apply -f https://raw.githubusercontent.com/kubealex/k8s-mediaserver-operator/master/k8s-mediaserver-operator.yml
kubectl apply -f plex/k8s-mediaserver.yml
