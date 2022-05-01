created with kustomize:

kubectl kustomize ../../metallb/ > bundle/config/upstream/install.yaml

Values:

namespace: metallb-system
ip_pool: 192.168.0.208/28