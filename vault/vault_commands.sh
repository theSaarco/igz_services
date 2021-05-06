vault secrets enable -path=secret kv-v2

vault auth enable kubernetes

vault write auth/kubernetes/config \
        token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
        kubernetes_host="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT_HTTPS" \
        kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

vault policy write mlrun-api-full /home/vault/mlrun_api_full_policy.hcl

vault write auth/kubernetes/role/mlrun-role-user-mlrun-api \
	bound_service_account_names=mlrun-api,jupyter-job-executor \
	bound_service_account_namespaces=default-tenant \
	policies=mlrun-api-full \
	ttl=12h
