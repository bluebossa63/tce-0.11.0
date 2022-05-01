tanzu package install cert-manager --package-name cert-manager.community.tanzu.vmware.com --version 1.6.1 -n tanzu-package-repo-global
kubens cert-manager
kubectl create secret tls niceneasy-ca --cert=/home/daniele/CA/ca.niceneasy.ch.crt --key=/home/daniele/CA/ca.niceneasy.ch.key
kubectl apply -f cert-manager/cluster-issuer.yaml 