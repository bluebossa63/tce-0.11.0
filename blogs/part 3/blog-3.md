# Tanzu Community Edition 0.11 - Tanzu Packaged Build Tools 
## Tanzu Packages

[The (Experimental) Application Toolkit](https://tanzucommunityedition.io/docs/main/package-readme-app-toolkit-0.2.0/) introduces an opinionated approach to CICD tooling with lots of interesting concepts. And it is even possible [to integrate some of it in the widely used argocd](https://carvel.dev/blog/argocd-carvel-plugin/). As an overall consideration, the interoperability and simplicity of the tools set is crucial to keep the complexity manageable.

This is the description of the latest version (0.2.0), I was working with 0.1.0:

|Name|Description|Version|
|:----|:----|:----|
|Cartographer|Cartographer allows you to create secure and reusable supply chains that define all of your application CI and CD in one place, in cluster.|0.3.0|
|Cartographer-Catalog|Reusable Cartographer Supply Chains and templates for driving workloads from source code to running Knative service in a cluster.|0.3.0|
|cert-manager|Cert Manager provides certificate management functionality.|1.6.1|
|Contour|Contour provides Ingress capabilities for Kubernetes clusters|1.20.1|
|Flux CD Source Controller|FluxCD Source specialises in artifact acquisition from external sources such as Git, Helm repositories and S3 buckets.|0.21.2|
|Knative Serving|Knative Serving provides the ability for users to create serverless workloads from OCI images|1.0.0|
|kpack|kpack provides a platform for building OCI images from source code.| |
|kpack-dependencies|kpack-dependencies provides a curated set of buildpacks and stacks required by kpack.|0.0.9|

cert-manager is creating a bootstrap problem, if you want to enforce a common custom CA. You have to keep the sequence to first install the cert-manager, then create secrets and clusterissuers. In my tests with 0.1.0 the installation failed because of cert-manager as well. I am not sure if the installation sequence is correctly designed or enforced. But you can exclude packages from beeing installed with the bundle, that's how I could meet my requirement of a custom CA.

## app-toolkit Installation

*The files I am referencing throughout my blog post can be found [here](https://github.com/bluebossa63/tce-0.11.0).*

I first installed cert-manager manually

```bash
tanzu package install cert-manager --package-name cert-manager.community.tanzu.vmware.com --version 1.6.1

#create custom certificate authority CA and cluster issuer
kubens cert-manager
kubectl create secret tls niceneasy-ca --cert=/home/daniele/CA/ca.niceneasy.ch.crt --key=/home/daniele/CA/ca.niceneasy.ch.key
kubectl apply -f cert-manager/cluster-issuer.yaml 
#create custom certificate authority
```
Then I could go with the package and the aggregated configuration values I tested by installing the packages one by one.

```bash
tanzu package install app-toolkit --package-name app-toolkit.community.tanzu.vmware.com --version 0.1.0 -f app-toolkit/values.yaml -n tanzu-package-repo-global

#please note excluded_packages: cert-manager in values.yaml

#don't forget to take this one if you're planning to use i.e. harbor registry with your custom CA
tanzu package install cert-injection-webhook --package-name cert-injection-webhook.community.tanzu.vmware.com --version 0.1.0 -f ./cert-injection-webhook/cert-injection-webhook-config-values.yaml
```
## Post-Deployment Tasks

If you are prepared so far you can now go ahead with the tests proposed in the documentation. They are based on [this repository](https://github.com/cgsamp/tanzu-simple-web-app) defining a simple spring boot web app. Simply fork it and use it for your tests with your personal fork. In the end you will have the app automatically rebuild and deployed - short time after you commited something to the main branch. You just have to change one line, check out the last paragraph of the readme.

If you are already working with my repository, you can rely on my files as well, you'll find them all in the [kpack](../../kpack/) directory. So let me add to the documentation with all what I have learned so far. The version 0.2.0 of the app-toolkit lists Cartographer-Catalog and kpack-dependencies - I think this is very promising and worth a follow-up. It is really a lot of tooling to get comfortable with to use it efficiently. The main promise of this philosophy is that you can simply state a git repo and some build packs will find the best way to deploy your workload. Let's start with the basics before we're trying to touch the limits...

I followed the [documentation of version 0.1.0](https://tanzucommunityedition.io/docs/v0.11/package-readme-app-toolkit-0.1.0/) and recommend the one of [kpack](https://tanzucommunityedition.io/docs/v0.11/package-readme-kpack-0.5.1/) and did a extended version:

Prepare rbac.yml:

```bash
apiVersion: v1
kind: Secret
metadata:
  name: registry-credentials
type: kubernetes.io/dockerconfigjson
stringData:
  .dockerconfigjson: | 
    {"auths":{"harbor.ne.local":{"auth":"<your hash>"},"https://index.docker.io/v1/":{"auth":"<your hash>"}}}
```
Please checkout the different formats for registry secrets that are supported:

https://github.com/pivotal/kpack/blob/main/docs/secrets.md 

https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.5/vmware-tanzu-kubernetes-grid-15/GUID-cluster-lifecycle-secrets.html

To get your docker auths simply do the login in docker on your cli and get 
```bash
docker login yourserver.com
docker login otherserver.com
jq -c . < ~/.docker/config.json 
```
minified.

```bash
kubectl apply -f kpack/rbac.yaml
kubectl apply -f kpack/kpack-templates.yaml
kubectl apply -f kpack/builder.yaml
```

The first manifest sets up some service accounts, credentials and roles. The second one is very interesting, I will refer to it in the following explanations. And with the third you can already test if your installation is working.


```bash
kubectl get builder
NAME      LATESTIMAGE                                                                                                       READY
builder   harbor.ne.local/tph-local/builder:1.2.0@sha256:a99661bd6ab75114f7418fd1d255f3567db2cda2f45194bddeaaa5d9f5530ce4   True
```
If you see something similar with the registry and the tag of your choice, you're ready to go. If it never gets ready just use 

```bash
kubectl describe builder <name>
```

to get more clues about the cause. I had a lot of certificate exceptions here when using my self-signed certificates. If you're using a public repository, you avoid this kind of trouble completely. Might be easier to begin with but you won't be able to use your own repository this way.

So if it does not work right from the start I recommend reading the [repository conventions](https://github.com/bluebossa63/tce-0.11.0/blob/master/README.md#repository-conventions) and check, if you really have adapted everything that is necessary. For the building process watch out for the following details:

```bash
kpack/kpack-values.yaml
kp_default_repository: harbor.ne.local/tph-local
kp_default_repository_username: sa-tph-mgmt

kpack/kpack-templates.yaml
  - name: image_prefix
    default: harbor.ne.local/tph-local/
```
Here you need to decide which directory you want to use and set the parameters accordingly together with valid registry credentials.
Again: if you want to use your own directory you have to prepare custom CAs.

## Principles

I invested quite some work to demo the basic functionality by changing or adding some of the definitions. Each of these components are quite powerful and documented. Let me add the following overall summary description.

*Contour* and *cert-manager* are not build tools but very important infrastructure components for ingress and certificate managers.

*Knative-Serving* offers a very easy publication of containers without bothering about kubernetes manifests or ingress definitions. It uses a wildcard domain and works with hostname based routing. 

*Cartographer* is the work flow engine orchestrating the steps defined in abstractions that are implemented in this app-toolkit with *kpack* and *Flux CD Source Controller*. [supplychain.yaml](../../kpack/supplychain.yaml) is the one from the documentation, [supplychain2.yaml](../../kpack/supplychain2.yaml) a variant I want to use to show how it works in detail. 

The original supplychain is designed to build from a repository and publish the container with Knative-Serving. My version uses my [Clarity template](https://github.com/bluebossa63/clarity-template), an angular app that uses the [Clarity Framework](https://clarity.design/) - something that might look familiar to you...

The supplychains are triggered either by installing them or if when the last commit hash of the repo has changed. You can install a [workload](../../kpack/workload.yaml) by cli

```bash
tanzu apps workload create -f ./kpack/workload.yaml

OR

kubectl apply -f ./kpack/workload.yaml
```
The workload definition consists simply of a source definition (here: git) and an important tag:

<pre>apps.tanzu.vmware.com/workload-type: web</pre>

This tag gets served by a supplychain with the correspondent selector:

<pre>  selector:
    apps.tanzu.vmware.com/workload-type: web</pre>

My variant works with the tag web-k8s on which my supplychain is listening.

Setting up my environment with [kpack-templates.yaml](../../kpack/kpack-templates.yaml) defines all the prerequisites to process a supplychain:

- ClusterStack and ClusterStore from *kpack* are defining which build packs should be used. Build packs are analyzing code and automatically detect programming langauges and target configurations.
- ClusterImageTemplate, ClusterSourceTemplate from cartographer are defining how to instantiate Images and Sources
- ClusterTemplate from cartographer is the most interesting one, here you'll find the tags again - original sample, my version....
```bash
app-deploy
app-deploy-k8s
```
- ServiceAccounts, Credentials...

Let's inspect the main part of the supplychain definition:
```yaml
  resources:
  - name: source-provider
    ...
  - name: image-builder
    ...
  - name: deployer
    ...
```

We have 3 build steps: fetch the source, build the image, deploy the container.

```yaml
  - name: deployer
    templateRef:
      kind: ClusterTemplate
      name: app-deploy
    images:
    - resource: image-builder
      name: image
```
The deploy step links to the ClusterTemplate with the name "app-deploy" - and, you guessed it, my supplychain links to "app-deploy-k8s" in  [kpack-templates.yaml](../../kpack/kpack-templates.yaml).

The first two steps are basically unchanged. I only changed the deployment step just by adding a new ClusterTemplate with the standard kubernetes manifest definitions for deployment, certificate and httpproxy (contour ingress).

As it is so easy to get the contents of a git repo deployed, I have created some additional samples to test the limits. A very interesting use case is the [google microservice sample](../../kpack/google-web-services-demo.yaml)...

Google introduces with [scaffold](https://skaffold.dev/) yet another build tool and has in this case a rather complicated 10-tier microservices application architecture in one repo. Of course it is possible to give subPath in the git source - but are all services rebuild when only on subpath has a change? And how could the *service bindings* be managed between the single images that are modeled with kpack? 