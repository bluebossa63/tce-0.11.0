jenkins converted from helm:

```yaml
apiVersion: vendir.k14s.io/v1alpha1
kind: Config
minimumRequiredVersion: 0.12.0
directories:
  - path: config/upstream
    contents:
      - path: .
        helmChart: 
          name: jenkins
          repository: 
            url: https://charts.bitnami.com/bitnami
```

in did not work. I have no clue how to generate the helm chart from there.

helm repo add bitnami https://charts.bitnami.com/bitnami  
helm install jenkins bitnami/jenkins --namespace jenkins --dry-run > jenkins/bundle/config/upstream/install.yaml

helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm install nexus-rm sonatype/nexus-repository-manager --namespace nexus -f nexus/values.yaml --dry-run > packaging/jenkins/bundle/config/upstream/install.yaml

as substitute...

2. Login with the following credentials

  echo Username: user
  echo Password: $(kubectl get secret --namespace jenkins jenkins2 -o jsonpath="{.data.jenkins-password}" | base64 --decode)