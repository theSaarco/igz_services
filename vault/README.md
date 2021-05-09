# Deploying Vault in an Iguazio system

> ## **Warning:**
>
> 1. This deployment script is intended for demo purposes only! It makes shortcuts which are easier to use, but generate a configuration which is not secure enough for production purposes.
> 2. For Vault functionality to work properly, you need at least MLRun **v0.6.2** or newer deployed on the system.

To deploy Vault do the following:

1. Pull this repository to the data node (must be the data node, since we need helm)
2. Execute the scripts provided:

    ```bash
    ./create_vault.bash
    ./unseal_and_configure.bash
    ```

## What you will have at the end of the process

After executing everything, you will have the following things deployed and configured:

1. A `vault` namespace
2. A `vault` Helm deployment in this namespace, which has a Vault server deployed. This has the following componenets installed:
   1. A `statefulset` and pods that will be deployed on your nodes. Specifically if you have a single node, a single pod `vault-0` will be installed
   2. Two services - one called `vault` which is a `ClusterIP` service exposing the `vault` pods, and another headless service used for internal communication with local pods called `vault-internal`
   3. The Vault pod has v3io fuse mount, so it can access v3io storage. It keeps the Vault internal storage on v3io. Specifically, the pod uses the `pipelines` user, and "borrows" the access key from the mlrun k8s fuse secret. The actual Vault storage is kept on `/User/vault/data`. The fuse mount and the path to storage are all configured in the [overrides.yaml](./overrides.yaml) file.
3. Vault will be initialized with a single-shard unseal key. It will also be unsealed and ready for use. A k8s secret called `vault-init` is created in the `vault` namespace that has two secret values in it:
   1. `root_token` - the root token which can be used to login to Vault and perform any configuration action
   2. `unseal_key` - the unseal key mentioned above (single shard) which can be used to unseal the Vault if it's locked for any reason
4. Vault will also have the following configured in it (these commands are all in the [vault_commands.sh](./vault_commands.sh) script):
   1. Secrets KV engine is enabled in the usual path (`/secret`)
   2. K8s authentication method is enabled and configured to authenticate with the local k8s cluster
   3. An `mlrun-api-full` policy is created which provides admin-level permissions on secrets and other Vault constructs
   4. An `mlrun-role-user-mlrun-api` role is created which allows MLRun and Jupyter pods to use the `mlrun-api-full` policy (connects it to their service-accounts)
5. The `mlrun-api` deployment is patched, adding needed env-variables pointing at the Vault service (the internal headless service) and the role, so that MLRun can work with Vault
6. The `jupyter` deployment is patched the same (note that this assumes you already have Jupyter installed in the system and it's called simply `jupyter`)
7. The `mlrun-api` k8s role is patched to add permissions on service-accounts, since MLRun needs to be able to create SAs as part of configuring project-level secret access with Vault

## Connecting to Vault and performing CLI operations

To perform any CLI operation on Vault, you can connect to the Vault pod, from there you can execute the `vault` command. To do this, run:

```bash
kubectl -n vault exec -it vault-0 -- /bin/sh
```

Once you're in the pod, run Vault CLI commands as usual. For example:

```bash
/ $ vault read auth/kubernetes/role/mlrun-role-user-mlrun-api
Key                                 Value
---                                 -----
bound_service_account_names         [mlrun-api jupyter]
bound_service_account_namespaces    [default-tenant]
policies                            [mlrun-api-full]
token_bound_cidrs                   []
token_explicit_max_ttl              0s
token_max_ttl                       0s
token_no_default_policy             false
token_num_uses                      0
token_period                        0s
token_policies                      [mlrun-api-full]
token_ttl                           12h
token_type                          default
ttl                                 12h
```

> **Note:**
>
> The installation scripts already performed `login` using `exec` on the pod, so you shouldn't need to re-login to Vault to perform actions. If a login is needed, you can use the root token to login.
