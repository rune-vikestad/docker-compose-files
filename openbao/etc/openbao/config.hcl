ui            = true
disable_mlock = true
api_addr      = "http://openbao:8200"
cluster_addr  = "http://openbao:8201"

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

# /openbao/file is owned by the openbao user in the image, so the volume inherits that ownership
storage "raft" {
  path    = "/openbao/file"
  node_id = "openbao"
}

# Unseals on every start, so a restart never needs a manual unseal
seal "static" {
  current_key_id = "local-1"
  current_key    = "env://BAO_STATIC_SEAL_KEY"
}

# Runs once, on first start against an empty volume. The init root token is revoked afterwards,
# so a long-lived token with a known id is created instead. It has to be an orphan, or it would
# be revoked together with its parent.
initialize "secrets" {
  request "mount-kv" {
    operation = "update"
    path      = "sys/mounts/secret"
    data = {
      type    = "kv"
      options = { version = "2" }
    }
  }
}

initialize "auth" {
  request "create-root-token" {
    operation = "update"
    path      = "auth/token/create-orphan"
    data = {
      id = {
        eval_type       = "string"
        eval_source     = "env"
        env_var         = "BAO_ROOT_TOKEN"
        require_present = true
      }
      policies     = ["root"]
      display_name = "root"
    }
  }
}
