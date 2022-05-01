2. Login with the following credentials

  echo Username: user
  echo Password: $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-password}" | base64 --decode)