vendir sync --chdir bundle
helm template vault \
    --set "server.dev.enabled=true" \
    --set "injector.enabled=false" \
    --set "csi.enabled=true" \
    ./bundle/config/helmchart-vault/ > ./bundle/config/upstream/01-vault-install.yaml
helm template secrets-store-csi-driver \
    ./bundle/config/helmchart-csi-driver/ > ./bundle/config/upstream/02-csi-install.yaml 