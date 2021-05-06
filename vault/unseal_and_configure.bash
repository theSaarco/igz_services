#! /bin/bash

ROOT_TOKEN=$(kubectl -n vault get secrets vault-init -o jsonpath='{.data.root_token}' | base64 -d)
UNSEAL_KEY=$(kubectl -n vault get secrets vault-init -o jsonpath='{.data.unseal_key}' | base64 -d)

kubectl -n vault cp vault_commands.sh vault-0:/home/vault/vault_commands.sh
kubectl -n vault cp mlrun_api_full_policy.hcl vault-0:/home/vault/mlrun_api_full_policy.hcl

kubectl -n vault exec -it vault-0 -- vault operator unseal $UNSEAL_KEY
kubectl -n vault exec -it vault-0 -- sh -c "echo $ROOT_TOKEN | vault login - ; source /home/vault/vault_commands.sh" 

kubectl -n default-tenant patch deployments.apps mlrun-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"mlrun-api","env":[{"name":"MLRUN_SECRET_STORES__VAULT__URL","value":"http://vault-internal.vault:8200"},{"name":"MLRUN_SECRET_STORES__VAULT__ROLE","value":"user:mlrun-api"}]}]}}}}'
kubectl -n default-tenant patch deployments.apps jupyter -p '{"spec":{"template":{"spec":{"containers":[{"name":"jupyter","env":[{"name":"MLRUN_SECRET_STORES__VAULT__URL","value":"http://vault-internal.vault:8200"},{"name":"MLRUN_SECRET_STORES__VAULT__ROLE","value":"user:mlrun-api"}]}]}}}}'
kubectl -n default-tenant patch role mlrun-api --type="json" -p='[{"op":"add", "path":"/rules/0/resources/-", "value": "serviceaccounts"}]'
