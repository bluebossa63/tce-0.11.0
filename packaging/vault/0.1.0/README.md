https://learn.hashicorp.com/tutorials/vault/kubernetes-secret-store-driver


helm install hashicorp-vault hashicorp/vault \
    --set "server.dev.enabled=true" \
    --set "injector.enabled=false" \
    --set "csi.enabled=true" --dry-run > packaging/vault/bundle/config/upstream/vault-install.yaml


    NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named hashicorp-vault. To learn more about the release, try:

  $ helm status hashicorp-vault
  $ helm get manifest hashicorp-vault



NOTES:
The Secrets Store CSI Driver is getting deployed to your cluster.

To verify that Secrets Store CSI Driver has started, run:

  kubectl --namespace=default get pods -l "app=secrets-store-csi-driver"

Now you can follow these steps https://secrets-store-csi-driver.sigs.k8s.io/getting-started/usage.html
to create a SecretProviderClass resource, and a deployment using the SecretProviderClass.
