# Data Lab Initial Configurations

After installing the Data Lab, there are still a few steps to be done to accomplish the expected behaviour.

## Initialize Vault

```
helm repo add eurostat-datalab https://eurostat.github.io/datalab/
helm repo update
helm show values eurostat-datalab/datalab > values.yaml
```

**IMPORTANT**: create your own `values.yaml` based on the default `values.yaml` with your domain name, SMTP server, and passwords.

> **ATTENTION** ensure you do not commit your `values.yaml` with secrets to the SCM.

```
helm upgrade --install datalab eurostat-datalab/datalab -f values.yaml --wait
```

After successful installation, configure HashiCorp's Vault to be used by Onyxia and Keycloak `jwt` authentication.
```bash
kubectl exec --stdin --tty datalab-vault-0 -- /bin/sh

# inside the pod... place both to 1 in development for ease of use
vault operator init -key-shares=5 -key-threshold=3

# ******************** IMPORTANT ******************** 
# Get Unseal Key shares and root token: keep them SAFE!
# ******************** IMPORTANT ********************

vault operator unseal # key share 1
vault operator unseal # key share 2
vault operator unseal # key share 3

# Run the mounted configmap with the root-token as env var
VAULT_TOKEN=<root-token> ./vault/scripts/configscript.sh
```

And enable CORS for Onyxia access.
```
curl --header "X-Vault-Token: <root-token>" --request PUT --data '{"allowed_origins": ["https://datalab.example.test", "https://vault.example.test" ]}'  https://vault.example.test/v1/sys/config/cors
```

## Restart MinIO

MinIO has some trouble configuring all authentication and policies services, so most times the deployment responsible form MinIO should be restarted in order to re-establish all configurations necessary.

```bash
kubectl rollout restart deploy {{ .Release.Name }}-dminio
```

## Set roles permissions on Superset

The roles in Apache Superset are set correctly, but to get the desired outcome out of them, we must rectify the priviledges in each of them. After logging in with the default admin, change the roles with the following rules: 

- Alpha role: add `can wirte on Database` & `menu access SQL Lab` & `can sql json on Superset` permission
- Gamma role: add `all database access on all_database_access` & `all datasource access on all_datasource_access` & `all query access on all_query_access` & `menu access SQL Lab` & `can sql json on Superset` permission