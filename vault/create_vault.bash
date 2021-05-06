#! /bin/bash

kubectl create namespace vault
helm repo add hashicorp https://helm.releases.hashicorp.com

USERNAME=$(kubectl -n default-tenant get secrets mlrun-v3io-fuse -o jsonpath='{.data.username}' | base64 -d)
ACCESS_KEY=$(kubectl -n default-tenant get secrets mlrun-v3io-fuse -o jsonpath='{.data.accessKey}' | base64 -d)
kubectl -n vault create secret generic vault-v3io-fuse --type='v3io/fuse' --from-literal=username=$USERNAME --from-literal=accessKey=$ACCESS_KEY

helm install vault hashicorp/vault -n vault -f overrides.yaml

ready=0
while [ $ready -eq 0 ]
do
  echo "Waiting for pod to be ready, sleeping 5 seconds..."
  sleep 5
  ready=$(kubectl -n vault get pods --selector='app.kubernetes.io/name=vault' | grep "1/1" | wc -l)
done

kubectl exec -n vault vault-0 -- /bin/vault operator init -n 1 -t 1 1>vault_keys

ROOT_TOKEN=$(awk -F ":" '/Initial Root Token/ {print $2}' vault_keys)
UNSEAL_KEY=$(awk -F ":" '/Unseal Key 1/ {print $NF}' vault_keys)

kubectl -n vault delete secret vault-init
kubectl -n vault create secret generic vault-init --from-literal=root_token="$ROOT_TOKEN" --from-literal=unseal_key="$UNSEAL_KEY"

rm -rf vault_keys
