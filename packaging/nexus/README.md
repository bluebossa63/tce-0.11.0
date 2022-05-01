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
          name: nexus-repository-manager
          repository: 
            url: https://sonatype.github.io/helm3-charts/
```

in did not work. I have no clue how to generate the helm chart from there.

helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm install nexus-rm sonatype/nexus-repository-manager --namespace nexus -f nexus/values.yaml --dry-run > packaging/jenkins/bundle/config/upstream/install.yaml

as substitute...