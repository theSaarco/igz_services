# Allow access to mlrun-api user-context secrets
path "secret/data/mlrun/users/mlrun-api" {
  capabilities = ["read", "list", "create", "update", "sudo"]
}

path "secret/data/mlrun/users/mlrun-api/*" {
  capabilities = ["read", "list", "create", "update", "sudo"]
}

# Allow access to secrets of all projects
path "secret/data/mlrun/projects/*" {
  capabilities = ["read", "list", "create", "update"]
}

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "auth/kubernetes/role/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
