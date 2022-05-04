# Tanzu Community Edition 0.11 - cluster config
Finally I found some time to get my hands on the latest release of the free version of Tanzu. I was very pleased with the progress made since I had the last touchpoint and I will have to split the material in multiple write-ups:
- In the first part I will post my findings regarding to certificate handling - covering the bootstrap configuration as well. 
- The second part will cover the package handling proposed by TCE. 
- The third part the build tools containted in the tanzu repository. 
- And a last part will put all the pieces together.
## Documentation
TCE has it's own community driven [documentation](https://tanzucommunityedition.io/docs/v0.11/). I'm pleased with the quality so far. The only topic I had to dig deeper was the usage of self-signed registries or CAs. If you don't plan to use registries without a well known CA, you just can start installing according to the documentation. And of course don't miss the awesome knowledge that can be picked up at any time at [Tanzu Developer Center](https://tanzu.vmware.com/developer/). 

I have published all files I have been using to [this repo](https://github.com/bluebossa63/tce-0.11.0). Please check out the README.md on the top level to be prepared for necessary adoptions.

# Cluster Configuration

## Custom Certificate Authorities
I found some hints in [this blog](https://neonmirrors.net/post/2020-10/using-custom-registries-with-tkg/) and in the [official documentation of Tanzu 1.5](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-cluster-lifecycle-secrets.html). The only topic I had to dig deeper was the usage of self-signed registries or CAs. If you don't plan to use registries without a well known CA, you just can start installing according to the documentation. And of course don't miss the awesome knowledge that can be picked up at any time at [Tanzu Developer Center](https://tanzu.vmware.com/developer/). I have published all files I have been using to [this repo](https://github.com/bluebossa63/tce-0.11.0). Please check out the README.md on the top level to be prepared for the used conventions.
I assume this approach works only during the bootstrap and can't be changed after the deployment. Following this steps you'll get your CA registered within for each VM Tanzu is running on.

You get a good understanding of the cluster configuration by performing a --dry-run before creating a cluster. This will generate the manifests that are consumed by the cluster manager to bootstrap a cluster.

```bash
tanzu cluster create tph-test -f cluster-config/tph-test.yaml --dry-run > cluster-config/tph-test-deploy.yaml
```
So the trick of doing these adaptions permanently is to change some config files in the tanz basic config - on my workstation located at ~/.config/tanzu/tkg/providers/infrastructure-vsphere/ytt I had to add [a ytt enabled yaml file](../../cluster-config/.config/tanzu/tkg/providers/infrastructure-vsphere/ytt/custom-ca.yaml) together with a [file containing the certificate](../../cluster-config/.config/tanzu/tkg/providers/infrastructure-vsphere/ytt/tkg-custom-ca.pem) itself.

If you put it here, this adoption is applied to each vshphere installation. This meets my requirements: I only plan to use my own vCenter with my custom CA used everywhere.

```yaml
apiVersion: bootstrap.cluster.x-k8s.io/v1beta1
kind: KubeadmConfigTemplate
metadata:
  name: tph-test-md-0
  namespace: default
spec:
  template:
    spec:
      files:
      - content: |
          -----BEGIN CERTIFICATE-----
          ************
          -----END CERTIFICATE-----
        owner: root:root
        path: /etc/ssl/certs/tkg-custom-ca.pem
        permissions: "0644"
      joinConfiguration:
        nodeRegistration:
          criSocket: /var/run/containerd/containerd.sock
          kubeletExtraArgs:
            cloud-provider: external
            tls-cipher-suites: TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
          name: '{{ ds.meta_data.hostname }}'
      preKubeadmCommands:
      - hostname "{{ ds.meta_data.hostname }}"
      - echo "::1         ipv6-localhost ipv6-loopback" >/etc/hosts
      - echo "127.0.0.1   localhost" >>/etc/hosts
      - echo "127.0.0.1   {{ ds.meta_data.hostname }}" >>/etc/hosts
      - echo "{{ ds.meta_data.hostname }}" >/etc/hostname
      - '! which rehash_ca_certificates.sh 2>/dev/null || rehash_ca_certificates.sh'
      - '! which update-ca-certificates 2>/dev/null || (mv /etc/ssl/certs/tkg-custom-ca.pem
        /usr/local/share/ca-certificates/tkg-custom-ca.crt && update-ca-certificates)'
      useExperimentalRetryJoin: true
      users:
      - name: capv
        sshAuthorizedKeys:
        - ssh-rsa ************
        sudo: ALL=(ALL) NOPASSWD:ALL
```
This is the KubeadmConfigTemplate for the nodes and as you can see, within preKubeadmCommands it is possible to do such things as registering a custom CA with the OS. If you check out the same template for the master nodes you'll find additional kubernetes manifests that are created before the bootstrap process starts. This is needed (together with the [kubelet flags](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/?ref=hackernoon.com)) for things like changing low level interfaces ([CNI](https://www.cni.dev/),[CSI](https://github.com/kubernetes-sigs/vsphere-csi-driver/tree/release-2.0/manifests/v2.0.2/vsphere-7.0/deploy)), admission controllers, authentication and similar advanced topics. 

> But: this is only half the solution. If you plan to use kpack - or any other service - together with a custom registry or a custom CA, you might need the CA also within your containers for the builds or service calls. Here TCE offers a prepared Tanzu package for the [Cert Injection Webhook](https://tanzucommunityedition.io/docs/v0.11/package-readme-cert-injection-webhook-0.1.1/). The [CA Injector of cert-manger](https://cert-manager.io/docs/concepts/ca-injector/) itself gets automatically installed at least in the mgmt-cluster and according to the documentation this version is used for webhooks mainly. I ignored the task to determine the difference between the two components, the one delivered with TCE is hosted [here](https://github.com/vmware-tanzu/cert-injection-webhook).

## Use a .local domain 

If you are using a domain like my ne.local you have to do additional steps to enable name resolution. If you don't do that you'll get "Temporary failure in name resolution". system-resloved is causing this issue because it considers itself als master of the whole top level domain "local". You can overcome this problem by explicitely setting the [DNS search path to this domain](https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-tanzu-k8s-clusters-config-plans.html#resolve-local)

# Installation
The installation is straightforward, this time I installed the TCE management cluster on my homelab on vCenter. [Last time](https://vdan.niceneasy.ch/tanzu-challenge-1/) I tested an installation first on docker on a AWS VM. As it is very well documented, I won't repeat the necessary steps. [This blog](https://www.virtuallypotato.com/ldaps-authentication-tanzu-community-edition/) is helpful to set up LDAP authentication.
For the first try, I just started the UI and created a minimal management cluster and immediately created a managed workload cluster.

As I wanted to keep everything as simple as possible, I did not install NSX Advanced Load Balancer (Avi) or HA-Proxy. Tanzu itself uses [kube-vip](https://kube-vip.chipzoller.dev/docs/) to create the API endpoint. Having some experiences with [metallb](https://metallb.org/), I decided to use these components to enable support for the [Services of type LoadBalancer](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/). 

*The files I am referencing throughout my blog post can be found [here](https://github.com/bluebossa63/tce-0.11.0).*

After adapting the CloudRoleBinding "tanzu-admins" to include my AD username, I could logon to the cluster and got the full admin rights. Of course, you can reach the same goal if you are using the provided kubeconfig with the same admin role.

```bash
tanzu mc get [--admin]
tanzu cluster kubeconfig get <WORKLOAD-CLUSTER-NAME> [--admin]
```

With these commands you can fetch the kubeconfig of either the management cluster (mc) or a workload clouster with the given name. If you specify --admin you'll get the kubernetes admin account, otherwise you'll get a kubeconfig, that redirects you to a login page, if your personal user token is expired.

```bash
tanzu cluster kubeconfig get tph-test --admin
kubectl config use-context tph-test-admin@tph-test
kubectl apply -f auth/auth.yaml
#adapt VIP IP pool according to your needs [here](../../metallb/metallb-cm.yml)
kubectl apply -k metallb
```
This gets the kubeconfig, sets the context, adapts the rbac and installs metallb on the **management cluster**. I want to use it also for shared services, repositories and build tools in the context of my home lab to minimize ressource consumption and TCE gives you full control also on the the management cluster. You just have to define a [default storage class](../../cluster-config/tce-storage-class.yaml), afterwards it behaves exactly like a managed workload cluster.

# Setup 

I spotted this diagram in the [cartographer documentation](https://cartographer.sh/docs/v0.3.0/multi-cluster/):

<img src="../part%201/images/multi-cluster.jpg" alt="https://cartographer.sh/docs/v0.3.0/multi-cluster/">

The "build" cluster is managing the process, CICD is triggered by git webhooks and can be fully automated or with manual approval through pull requests. For a minimal installation I decided to create a development management cluster with 3 medium nodes (2 vCPUs, 16 GB RAM) to host monitoring and build tools. As tanzu itself is able to manage kubernetes clusters on any cloud, this cluster could become a developers dream: just push your app to git and have it immediately deployed wherever it fits best. A cluster can be created only for some tests. 

TCE offers a curated catalog which I took as a design guideline. Tanzu packaging, however, is fully open and extensible. I tested this with vault, nexus and argocd and with the plex server, the topic of the [Tanzu Challenge #1](https://vdan.niceneasy.ch/tanzu-challenge-1/) - and all as tanzu packages.

Stay tuned for the documentation and the full example. Reliable automation requires a lot of work before you can install anything.

&nbsp;

*And thanks for the acknowledgement as an vExpert Application Modernization!*
<table style="border:none">
<tbody>
<tr style="border:none">
<td style="border:none"><img class="alignleft wp-image-26374 size-medium" src="https://vdan.niceneasy.ch/wp-content/uploads/2022/05/vExpert-App-Mod-2022-Badge.2.01-300x198.png" alt="" /></td>
<td style="border:none"><img class="wp-image-26373 alignright" src="https://vdan.niceneasy.ch/wp-content/uploads/2022/05/stars-300x203.png" alt=""  /></td>
</tr>
</tbody>
</table>

