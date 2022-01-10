# Data Lab Helm Chart based on Onyxia, Keycloak, MinIO&reg;, HashiCorp's Vault, Ckan, Prometheus and Grafana;

- [Onyxia](https://github.com/InseeFrLab/onyxia) is a web app that aims at being the glue between multiple open source backend technologies to provide a state of art working environnement for data scientists. Onyxia is developed by the French National institute of statistic and economic studies (INSEE).
- [Keycloak](https://www.keycloak.org/) is a high performance Java-based identity and access management solution. It lets developers add an authentication layer to their applications with minimum effort.
- [MinIO&reg;](https://min.io/) is an object storage server, compatible with Amazon S3 cloud storage service, mainly used for storing unstructured data (such as photos, videos, log files, etc.).
- [HashiCorp's Vault](https://www.vaultproject.io/) is a secrets manager build by HashiCorp to secure, store and tightly control access to tokens, passwords, certificates, encryption keys for protecting secrets and other sensitive data using a UI, CLI, or HTTP API.
- [Prometheus](https://prometheus.io/) is a metrics collector and alert manager component.
- [Grafana](https://grafana.com/) is an observability tool to add value to the collected metrics.
- [Ckan](https://ckan.org/) is a data management system. For the purpose of this project it will be used as a data catalog.
- (OPTIONAL) [PostgreSQL](https://www.postgresql.org/) is a powerful, open source object-relational database system with over 30 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.



**Disclaimer**: All software products, projects and company names are trademark&trade; or registered&reg; trademarks of their respective holders, and use of them does not imply any affiliation or endorsement. Keycloak is licensed under Apache License v2.0. MinIO&reg; is licensed under GNU AGPL v3.0. HashiCorp's Vault Chart is licensed under MPL-2.0 License. Grafana is licensed under GNU AGPL v3.0. Prometheus is licensed under Apache License v2.0. Ckan is licensed under GNU AGPL v3.0.

## TL;DR
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

Finally, if you want to use the groups feature, you'll have to configure policies for each group you create, a helper script can be found at `helpers/vault-groups-config.sh`.

## Introduction

This Chart wraps the necessary services to launch a complete data lab on a [Kubernetes](https://kubernetes.io/) cluster using [Helm](https://helm.sh/) package manager. It provisions the central component of the data lab [Onyxia](https://github.com/InseeFrLab/onyxia), and the necessary peripheral components to handle IAM ([Keycloak](https://www.keycloak.org/)), Storage ([MinIO&reg;](https://min.io/)), Secrets Management ([HashiCorp's Vault](https://www.vaultproject.io/)), Monitoring ([Prometheus](https://prometheus.io/)+[Grafana](https://grafana.com/)) and Data Catalog ([Ckan](https://ckan.org/)).

## Prerequisites

This Chart has the prerequisistes explained in the [docs](../../docs/DEPLOYMENT.md):
- Kubernetes 1.20
- Helm 3
- PV provisioner support in the underlying infrastructure
- Ingress controller
- Domain name and records pointing to the ingress controller
- (RECOMMENDED) wildcard TLS certificate configured for the ingress controller
- (OPTIONAL) SMTP server for user `Forgot password?` interactions and admin user account imposed actions
- (OPTIONAL) Ckan image with SSO configuration (Ckan extension + Keycloak Client definition)

## Dependencies

The dependencies of the Chart are the components of the data lab with:
- [Onyxia InseeFrLab Chart](https://github.com/InseeFrLab/helm-charts/tree/master/charts/onyxia) which needs extensive configuration in the `values.yaml`.
- [Keycloak Codocentric Chart](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak) which has subdependency [PostgreSQL Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/postgresql) with **recommended** configuration to use PV.
- [MinIO&reg; Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/minio) which has **recommended** PV dependency.
- [HashiCorp's Vault Chart](https://github.com/hashicorp/vault-helm) which will be configured after start-up to be used with Keycloak and Onyxia.
- [Ckan Chart](https://github.com/keitaroinc/ckan-helm) which will be configured during start-up to be used with Keycloak (with a pre-defined client). This chart has a few subdependencies:
  - [PostgreSQL Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/postgresql) with **recommended** configuration to use PV.
  - [Redis Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/redis)
  - [Solr Bitnami Chart](https://github.com/helm/charts/tree/master/incubator/solr)
  - [Datapusher Bitnami Chart](https://github.com/keitaroinc/ckan-helm/tree/master/dependency-charts/datapusher)

## Installing the Chart

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

# inside the pod...
vault operator init

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

Finally, if you want to use the groups feature, you'll have to configure policies for each group you create, a helper script can be found at `helpers/vault-groups-config.sh`.

## Uninstalling the Chart

This will delete the whole Chart. However, keep in mind that launched services during the utilization of the data lab will still be running. You will have to delete them from the user's namespaces.

```console
helm uninstall datalab
```

The PVCs created also remain after the previous command, so it might be necessary to delete them as well.

```console
kubectl delete pvc <pvc name|--all>
```

## Configurable Parameters

### Global

| Name                |  Description                                                                                | Value              |
| ------------------- | ------------------------------------------------------------------------------------------- | ------------------ |
| domainName          | **REQUIRED** Your owned domain name which will serve as root for the generated sub-domains  | `""`               |
| smtpServer          | Configuration for Keycloak to connect to your SMTP server                                   | `""`               |

The SMTP server configuration format would be:
```yaml
smtpServer: |- 
  {
    "password": "",
    "starttls": "",
    "auth": "",
    "port": "",
    "host": "",
    "from": "",
    "fromDisplayName": "",
    "ssl": "",
    "user": ""
  }
```

### Onyxia
For more information on Onyxia configurations visit the available documentation on [InseeFrLab Onyxia](https://github.com/InseeFrLab/onyxia), and take a look at the Chart on [Onyxia InseeFrLab Chart](https://github.com/InseeFrLab/helm-charts/tree/master/charts/onyxia).

Generic

| Name                                 |  Description                                                  | Value                 |
| ------------------------------------ | ------------------------------------------------------------- | --------------------- |
| `onyxia.serviceAccount.create`       | Service account creation for the pods                         | `true`                |
| `onyxia.serviceAccount.clusterAdmin` | ClusterRoleBinding for Onyxia API pod, needed for multi-user  | `false`               |
| `onyxia.ingress.enabled`             | Ingress resource enabled                                      | `false`               |
| `onyxia.ingress.annotations`         | Ingress annotations                                           | `{}`                  |
| `onyxia.ingress.hosts`               | Ingress resource hosts list                                   | See below             |
| `onyxia.ingress.hosts[0].host`       | Ingress resource host                                         | `chart-example.local` |
| `onyxia.ingress.hosts[0].secretName` | TLS secret name                                               | `""`                  |

Values for Onyxia UI:

| Name                          |  Description                                                         | Value                  |
| ----------------------------- | -------------------------------------------------------------------- | ---------------------- |
| `onyxia.ui.name`              | Pod name building component                                          | `ui`                   |
| `onyxia.ui.replicaCount`      | Number of replicas, since Onyxia is stateless                        | `1`                    |
| `onyxia.ui.image.name`        | Image name for Onyxia Web                                            | `inseefrlab/onyxia-web`|
| `onyxia.ui.image.version`     | Image version, keep to latest to ensure compatibilities with Catalogs| `latest`               |
| `onyxia.ui.image.pullPolicy`  | Pull policy to keep the image up to date                             | `Always`               |
| `onyxia.ui.podSecurityContext`| Pod security context                                                 | `{}`                   |
| `onyxia.ui.securityContext`   | Container security context                                           | `{}`                   |
| `onyxia.ui.service.type`      | Pod exposure service type                                            | `ClusterIP`            |
| `onyxia.ui.service.port`      | Pod exposure service port                                            | `80`                   |
| `onyxia.ui.resources`         | Pod resources requests and limitations                               | `{}`                   |
| `onyxia.ui.nodeSelector`      | Node selector                                                        | `{}`                   |
| `onyxia.ui.tolerations`       | Pod tolerations                                                      | `[]`                   |
| `onyxia.ui.affinity`          | Pod affinity, e.g. use anti afinity with `replicaCount > 1`         | `{}`                   |
| `onyxia.ui.env`               | Pod environment variables. Required to set some **(1)**              | `{}`                   |

If it is pretended to achieve a datalab with a data catalog (Ckan) available, an image of `onyxia-web` should be created in order to add an interface (or a link) to connect to this data catalog. Which implies that the value of `onyxia.ui.image` should also be updated:

```yml
onyxia:
  ui:
    name: ui
    image:
      name: <publisher>/onyxia-web
      version: <latest | tag> 
```

**(1)** Onyxia UI environment variables to set are as follows in the example with your own domain name to enable OIDC, MINIO access, and URL for the data catalog (Ckan):
```yaml
      OIDC_REALM: datalab-demo
      OIDC_CLIENT_ID: onyxia-client
      OIDC_URL: https://keycloak.example.test/auth
      MINIO_URL: https://minio.example.test
      REACT_APP_DATA_CATALOG_URL: ckan
      REACT_APP_DOMAIN_URL: example.test
```


Values for Onyxia API:

| Name                            |  Description                                                        | Value                  |
| ------------------------------- | ------------------------------------------------------------------- | ---------------------- |
| `onyxia.api.name`               | Pod name building component                                         | `api`                  |
| `onyxia.api.replicaCount`       | Number of replicas, since Onyxia is stateless                       | `1`                    |
| `onyxia.api.image.name`         | Image name                                                          | `inseefrlab/onyxia-api`|
| `onyxia.api.image.version`      |Image version, keep to latest to ensure compabilities with Catalogs  | `latest`               |
| `onyxia.api.image.pullPolicy`   | Pull policy to keep the image up to date                            | `Always`               |
| `onyxia.api.podSecurityContext` | Pod security context                                                | `{}`                   |
| `onyxia.api.securityContext`    | Container security context                                          | `{}`                   |
| `onyxia.api.service.type`       | Pod exposure service type                                           | `ClusterIP`            |
| `onyxia.api.service.port`       | Pod exposure service port                                           | `80`                   |
| `onyxia.api.resources`          | Pod resources requests and limitations                              | `{}`                   |
| `onyxia.api.nodeSelector`       | Node selector                                                       | `{}`                   |
| `onyxia.api.tolerations`        | Pod tolerations                                                     | `[]`                   |
| `onyxia.api.affinity`           | Pod affinity, e.g. use anti afinity with `replicaCount > 1`        | `{}`                   |
| `onyxia.api.env`                | Pod environment variables  Required to set some **(2)**             | `{}`                   |
| `onyxia.api.regions`            | Region configuration for this Onyxia API **(3)**                    | `[]`                   |
| `onyxia.api.catalogs`           | Catalogs of services to launch for this Onyxia API **(4)**          | `[]`                   |

**(2)** Onyxia API environment variables to set are as follows in the example with your own domain name to enable OIDC:
```yaml
      keycloak.realm: datalab-demo
      keycloak.auth-server-url: https://keycloak.example.test/auth
      authentication.mode: "openidconnect"
      springdoc.swagger-ui.oauth.clientId: onyxia-client
      catalog.refresh.ms: "300000"
```

**(3)** The Regions are configuration blocks that be stored as `ConfigMap` to indicate which endpoints and behaviours the service will have. Make sure to use your own domain name and hosts in the configuration. A given example is the following:
```json
[
  {
    "id": "demo",
    "name": "Demo",
    "description": "This is a demo region, feel free to try Onyxia !",     
    "onyxiaAPI": {
      "baseURL": ""
    },
    "services": {
      "type": "KUBERNETES",
      "initScript": "https://git.lab.sspcloud.fr/innovation/plateforme-onyxia/services-ressources/-/raw/master/onyxia-init.sh",
      "singleNamespace": false,
      "namespacePrefix": "user-",
      "usernamePrefix": "oidc-",
      "groupNamespacePrefix": "projet-",
      "groupPrefix": "oidc-",
      "authenticationMode": "admin",
      "quotas": { 
        "enabled": false,
        "allowUserModification": true,
        "default": {
          "requests.memory": "10Gi",
          "requests.cpu": "10",
          "limits.memory": "10Gi",
          "limits.cpu": "10",
          "requests.storage": "100Gi",
          "count/pods": "50"
        }
      },
      "defaultConfiguration": {
        "IPProtection": true,
        "networkPolicy": true
      },
      "expose": { "domain": "example.test" },
      "monitoring": { "URLPattern": "https://graphana.example.test/<path/to/your/dashboard>?orgId=1&refresh=5s&var-namespace=$NAMESPACE&var-instance=$INSTANCE" },
      "cloudshell": {
        "catalogId": "inseefrlab-helm-charts-datascience",
        "packageName": "cloudshell"
      },
    },
    "data": { 
      "S3": { 
        "URL": "https://minio.example.test", 
        "monitoring": { 
          "URLPattern": "https://graphana.example.test/<path/to/your/dashboard>?orgId=1&var-username=$BUCKET_ID"
        } 
      } 
    },
    "auth": { "type": "openidconnect" },
    "location": { "lat": 48.8164, "long": 2.3174, "name": "Montrouge (France)" }
  }
]
```

**(4)** The Catalogs are a list of available Helm repositories for Charts to be installed in Onyxia. Currently there is an available repository at [INSEE - Helm Charts Data Science](https://github.com/InseeFrLab/helm-charts-datascience) that can be used for Onyxia:
```json
[
  {
    "id": "inseefrlab-helm-charts-datascience",
    "name": "Inseefrlab datascience",
    "description": "Services for datascientists. https://github.com/InseeFrLab/helm-charts-datascience",
    "maintainer": "innovation@insee.fr",
    "location": "https://inseefrlab.github.io/helm-charts-datascience",
    "status": "PROD",
    "type": "helm",
  }
]
```



### Keycloak
For an exhaustive list on Keycloak configurations visit the available documentation on [Keycloak Codocentric Chart](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak), and for the sub-dependency visit the [PostgreSQL Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/postgresql).

It is recommended to set the following values:

Generic

| Name                                          |  Description                                                                    | Value                                      |
| --------------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------ |
| `keycloak.replicas`                           | The number of replicas to create                                                | `1`                                        |
| `keycloak.extraEnv`                           | Additional environment variables for Keycloak                                   | `""`                                       |
| `keycloak.rbac.create`                        | Specifies whether RBAC resources are to be created                              | `false`                                    |
| `keycloak.rbac.rules`                         | Custom RBAC rules, e.g. for KUBE_PING                                          | `[]`                                       |
| `keycloak.extraVolumes`                       | Add additional volumes, e.g. realm configuration                               | `""`                                       |
| `keycloak.extraVolumeMounts`                  | Add additional volumes mounts, e.g. realm configuration                        | `""`                                       |
| `keycloak.affinity`                           | Pod affinity                                                                    | Hard node and soft zone anti-affinity      |

The value `keycloak.extraEnv`, if using a more than one replica, should also include a node discovery method, e.g. `KUBE_PING` as indicated by the Chart providers in the [documentation](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak#kube_ping-service-discovery).

Network

| Name                                          |  Description                                                                    | Value                                      |
| --------------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------ |
| `keycloak.ingress.enabled`                    | If `true`, an Ingress is created                                                | `false`                                    |
| `keycloak.ingress.rules`                      | List of Ingress Ingress rule                                                    | See below                                  |
| `keycloak.ingress.rules[0].host`              | Host for the Ingress rule                                                       | `{{ .Release.Name }}.keycloak.example.com` |
| `keycloak.ingress.rules[0].paths`             | Paths for the Ingress rule                                                      | See below                                  |
| `keycloak.ingress.rules[0].paths[0].path`     | Path for the Ingress rule                                                       | `/`                                        |
| `keycloak.ingress.rules[0].paths[0].pathType` | Path Type for the Ingress rule                                                  | `Prefix`                                   |
| `keycloak.ingress.servicePort`                | The Service port targeted by the Ingress                                        | `http`                                     |
| `keycloak.ingress.annotations`                | Ingress annotations                                                             | `{}`                                       |


PostgreSQL sub-dependency parameters to be set are:

| Name                                     |  Description                                            | Value      |
| ---------------------------------------- | ------------------------------------------------------- | ---------- |
| `keycloak.postgresql.enabled`            | If `true`, the Postgresql dependency is enabled         | `true`     |
| `keycloak.postgresql.postgresqlUsername` | Value for PostgreSQL username                           | `""` |
| `keycloak.postgresql.postgresqlPassword` | Value for PostgreSQL password                           | `""` |
| `keycloak.postgresql.postgresqlDatabase` | PostgreSQL Database to create                           | `""` |


### MinIO&reg;

For an exhaustive list on MinIO&reg; configurations visit the available documentation on [MinIO&reg; Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/minio).

Generic 

| Name                        |  Description                                           | Value        |
| --------------------------- | ------------------------------------------------------ | ------------ |
| `minio.enabled`             | Enable for Keycloak to create a client for MinIO&reg;  | `true`       |
| `minio.mode`                | MinIO&reg; server mode (`standalone` or `distributed`) | `standalone` |
| `minio.accessKey.password`  | Root user access key                                   | `""`         |
| `minio.secretKey.password`  | Root user secret key                                   | `""`         |
| `minio.extraEnv`            | Extra environment variables                            | `""`         |

The value for `minio.extraEnv`, if using Keycloak SSO should contain the following (with your domain):

```yml
    - name: MINIO_IDENTITY_OPENID_CONFIG_URL
      value: "https://keycloak.example.test/auth/realms/datalab-demo/.well-known/openid-configuration"
    - name: MINIO_IDENTITY_OPENID_CLIENT_ID
      value: minio
    - name: MINIO_DOMAIN
      value: "minio.example.test"
    - name: MINIO_IDENTITY_OPENID_CLAIM_NAME
      value: policy
    - name: MINIO_IDENTITY_OPENID_REDIRECT_URI
      value: https://minio-console.example.test/oauth_callback
    - name: MINIO_IDENTITY_OPENID_SCOPES
      value: openid,profile,email,roles
```

Persistence

| Name                        | Description                                                          | Value               |
| --------------------------- | -------------------------------------------------------------------- | ------------------- |
| `persistence.enabled`       | Enable MinIO&reg; data persistence using PVC. If false, use emptyDir | `true`              |
| `persistence.storageClass`  | PVC Storage Class for MinIO&reg; data volume                         | `""`                |
| `persistence.mountPath`     | Data volume mount path                                               | `/data`             |
| `persistence.accessModes`   | PVC Access Modes for MinIO&reg; data volume                          | `["ReadWriteOnce"]` |
| `persistence.size`          | PVC Storage Request for MinIO&reg; data volume                       | `8Gi`               |
| `persistence.annotations`   | Annotations for the PVC                                              | `{}`                |
| `persistence.existingClaim` | Name of an existing PVC to use (only in `standalone` mode)           | `""`                |

Network

| Name                           |  Description                                         | Value                    |
| ------------------------------ | ---------------------------------------------------- | ------------------------ |
| `minio.ingress.enabled`        | Enable ingress controller resource                   | `false`                  |
| `minio.ingress.hostname`       | Default host for the ingress resource                | `minio.local`            |
| `minio.ingress.annotations`    | Additional annotations for the Ingress resource      | `{}`                     |
| `minio.apiIngress.enabled`     | Enable API ingress controller resource               | `false`                  |
| `minio.apiIngress.hostname`    | Default host for the API ingress resource            | `minio.local`            |
| `minio.apiIngress.annotations` | Additional annotations for the API Ingress resource  | `{}`                     |

### HashiCorp's Vault

For an exhaustive list on HashiCorp's Vault configurations visit the available documentation on [HashiCorp's Vault Chart](https://github.com/hashicorp/vault-helm). The used configurations in the datalab are:


| Name                                  |  Description                                         | Value                    |
| ------------------------------------- | ---------------------------------------------------- | ------------------------ |
| `vault.global.tlsDisable`             | Disable TLS for end-to-end encrypted transport       | `true`                   |
| `vault.server.enabled`                | Enable a server (injector can use external servers)  | `true`                   |
| `vault.server.ingress.enabled`        | Enable ingress controller resource                   | `false`                  |
| `vault.server.ingress.hosts`          | List of hosts for the ingress resource               | See Below                |
| `vault.server.ingress.hosts[0].host`  | Hostname for the ingress                             | `chart-example.local`    |
| `vault.server.ingress.annotations`    | Additional annotations for the Ingress resource      | `{}`                     |
| `vault.server.volumes`                | List of volumes made available to all containers     | `null`                   |
| `vault.server.volumeMounts`           | List of volumeMounts for the main server container   | `null`                   |
| `vault.server.dataStorage`            | Configuration for the PVCs to be used                | See Below                |
| `vault.server.dataStorage.size`       | Configuration of the size in the PVCs to be used     | `10Gi`                   |
| `vault.server.volumeMounts`           | List of volumeMounts for the main server container   | `null`                   |
| `vault.server.ha.enabled`             | Enable the Hight-Availability deployment mode        | `false`                  |
| `vault.server.ha.replicas`            | Number of replicas for the HA set-up                 | `3`                      |
| `vault.server.ha.raft`                | Raft configuration for the HA backend                | See Below                |
| `vault.server.ha.raft.enable`         | Enable raft backend for the HA set-up                | `false`                  |

```yaml
vault:
  server:
    ingress:
      hosts:
        - host: vault.example.test
    dataStorage:
      size: 5Gi
    ha:
      raft:
        enabled: false
        setNodeId: false
```

Note that `volumes` and `volumesMounts` are declared similar to usual Kubernetes manifests. For example, it is advised to use a configmap to mount the init script with:
```yaml
    volumes:
      - name: config-vol
        configMap:
          name: vault-scripts
          defaultMode: 0777
    volumeMounts:
      - mountPath: /vault/scripts/
        name: config-vol
        readOnly: false
```

### Prometheus
For an exhaustive configuration on Prometheus configurations visit the available documentation on [Prometheus Community Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus).

| Name                                                 | Description                                                             | Default Value                 |
| ---------------------------------------------------- | ----------------------------------------------------------------------- | ----------------------------- |
| `prometheus.alertmanager`                            | [Altermanager](https://github.com/prometheus/alertmanager) configuration block  | See Below             |
| `prometheus.alertmanager.enabled`                    | To enable the Prometheus Alertmanager                                   | `true`                        |
| `prometheus.nodeExporter`                            | [NodeExporter](https://github.com/prometheus/node_exporter) configuration block  | See Below            |
| `prometheus.nodeExporter.enabled`                    | To enable the Prometheus NodeExporter                                   | `true`                        |
| `prometheus.pushgateway`                             | [PushGateway](https://github.com/prometheus/pushgateway) configuration block  | See Below               |
| `prometheus.pushgateway.enabled`                     | To enable the Prometheus PushGateway                                    | `true`                        |
| `prometheus.server`                                  | Server configuration block                                              | See Below                     |
| `prometheus.server.enabled`                          | To enable the Prometheus Server                                         | `true`                        |
| `prometheus.alertmanagerFiles`                       | Configmap entries for Alertmanager                                      | alertmanager.yml              |

```yaml
prometheus:
  alertmanager:
    enabled: true
  nodeExporter:
    enabled: true
  pushgateway:
    enabled: true
  server:
    enabled: true   
```

It is recommended to configure the Alertmanager, it can be done through the `alertmanagerFiles`, with more information on configuration available on the [Official Documentation](https://prometheus.io/docs/alerting/latest/configuration/):

```yaml
    alertmanager.yml:
      global:
        resolve_timeout: 5m
        http_config:
          follow_redirects: true
        smtp_from: example@example.test # your smtp_from
        smtp_smarthost: example.smtp.test:587 # your smtp_host:port
        smtp_auth_username: example@example.test # your smtp username
        smtp_auth_password: <redacted> # your smtp password
        smtp_require_tls: true
      route:
        receiver: default-receiver
        continue: false
        group_wait: 10s
        group_interval: 5m
        repeat_interval: 3h
      receivers:
        - name: default-receiver
          email_configs:
            - to: example@example.test # your smtp email
      templates: []
```

### Grafana
For an exhaustive list on Grafana configurations visit the available documentation on [Grafana Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana). 

| Name                                              | Description                                   | Default Value                                           |
| ------------------------------------------------- | --------------------------------------------- | ------------------------------------------------------- |
| `grafana.adminUser`                               | Admin user when not using a secret            | `admin`                                                 |
| `grafana.adminPassword`                           | Admin password when not using a secret        | `""`                                        |
| `grafana.ingress.enabled`                         | Enables Ingress                               | `false`                                                 |
| `grafana.ingress.annotations`                     | Ingress annotations (values are templated)    | `{}`                                                    |
| `grafana.ingress.hosts`                           | Ingress accepted hostnames                    | `["chart-example.local"]`                               |
| `grafana.ingress.tls`                             | Ingress TLS configuration                     | `[]`                                                    |
| `grafana.sidecar.dashboards.enabled`              | Enables the cluster wide search for dashboards and adds/updates/deletes them in grafana | `false`       |
| `grafana.sidecar.datasources.enabled`             | Enables the cluster wide search for datasources and adds/updates/deletes them in grafana |`false`       |
| `grafana.datasources`                             | Configure grafana datasources (passed through tpl) | `{}`                                               |
| `grafana.dashboards`                              | Dashboards to import                          | `{}`                                                    |
| `grafana.dashboardProviders`                      | Configure grafana dashboard providers         | `{}`                                                    |
| `grafana.grafana.ini`                             | Grafana's primary configuration               | `{}`                                                    |

To configure Prometheus as a datasource for Grafana you should set the following values in `datasources`:
```yaml
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          url: http://{{ .Release.Name }}-prometheus-server.{{ .Release.Namespace }}.svc.cluster.local
          access: proxy
          isDefault: true
          jsonData:
            timeInterval: 30s
```

The values `grafana.ini`, if using Keycloak SSO, should contain the following (with your domain):
```yaml
  grafana.ini:
    server:
      root_url: https://grafana.example.test
    auth.generic_oauth:
      enabled: true
      scopes: "openid profile email"
      auth_url: https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/auth
      token_url: https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/token
      api_url: https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/userinfo
      client_id: grafana
      signout_redirect_url: https://grafana.example.test
```

Dashboards can be created from ConfigMaps during the Helm Chart installation with the `sidecar` value set to look for specificl labels:
```yaml
  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
```

### Ckan

Once Ckan also has a dependency on PostgreSQL, as Keycloak, we managed to create a condition that lets the developer configure this Helm Chart with only one PostgreSQL or multiple. Once having multiple databases depends on launching each instance with mostly pre-determined values, in this example we will state the values to launch only one database. 

For an exhaustive list on Ckan configurations visit the available chart description on [Ckan-Helm Github Repo](https://github.com/keitaroinc/ckan-helm). The used configurations in the datalab are:

Generic

| Key                                | Description                                                                                                                   | Value                    |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|--------------------------|
| `ckan.clientsecret`                | Client secret for CKAN Oauth client                                                                                           | `""`                     | 
| `ckan.image.pullPolicy`            | Pull policy to keep the image up to date                                                                                      | `"IfNotPresent"`         | 
| `ckan.image.repository`            | Image to pull                                                                                                                 | `"keitaro/ckan"`         | 
| `ckan.image.tag`                   | Tag of image to pull                                                                                                          | `"2.9.2"` |  
| `ckan.DBDeploymentName`            | Variable for name override for postgres deployment                                                                            | `"postgres"` |
| `ckan.DBHost`                      | Variable for name of headless svc from postgres deployment                                                                    | `"postgres"` |
| `ckan.MasterDBName`                | Variable for name of the master user database in PostgreSQL                                                                   | `"ckan"` | 
| `ckan.MasterDBPass`                | Variable for password for the master user in PostgreSQL                                                                       | `"pass"` | 
| `ckan.MasterDBUser`                | Variable for master user name for PostgreSQL                                                                                  | `"postgres"` | 
| `ckan.CkanDBName`                  | Variable for name of the database used by CKAN                                                                                | `"ckan_default"` | 
| `ckan.CkanDBPass`                  | Variable for password for the CKAN database owner                                                                             | `"pass"` | 
| `ckan.CkanDBUser`                  | Variable for username for the owner of the CKAN database                                                                      | `"ckan_default"` | 
| `ckan.DatastoreDBName`             | Variable for name of the database used by Datastore                                                                           | `"datastore_default"` | 
| `ckan.DatastoreRODBPass`           | Variable for password for the datastore database user with read access                                                        | `"pass"` | 
| `ckan.DatastoreRODBUser`           | Variable for username for the user with read access to the datastore database                                                 | `"datastorero"` | 
| `ckan.DatastoreRWDBPass`           | Variable for password for the datastore database user with write access                                                       | `"pass"` | 
| `ckan.DatastoreRWDBUser`           | Variable for username for the user with write access to the datastore database                                                | `"datastorerw"` | 

Network

| Key                                | Description                                                                                                                   | Value                    |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|--------------------------|
| `ckan.ingress.annotations`         | Ingress annotations                                                                                                           | `{}` | 
| `ckan.ingress.enabled`             | Ingress enablement                                                                                                            | `true` | 
| `ckan.ingress.hosts[0].host`       | Ingress resource hosts list                                                                                                   | `"chart-example.local"` |
| `ckan.ingress.hosts[0].paths`      | Ingress resource hosts' path list                                                                                             | `[/]` |
| `ckan.ingress.tls[0].hosts`        | Ingress resource tls hosts list                                                                                               | `"chart-example.local"` |

Ckan Specifications

| Key                                | Description                                                                                                                   | Value                    |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|--------------------------|
| `ckan.ckan.siteUrl`                | Url for the CKAN instance                                                                                                     | `"http://localhost:5000"`| 
| `ckan.ckan.psql.initialize`        | Flag whether to initialize the PostgreSQL instance with the provided users and databases                                      | `true` | 
| `ckan.ckan.psql.masterDatabase`    | PostgreSQL database for the master user                                                                                       | `"postgres"` | 
| `ckan.ckan.psql.masterPassword`    | PostgreSQL master user password                                                                                               | `"pass"` | 
| `ckan.ckan.psql.masterUser`        | PostgreSQL master username                                                                                                    | `"postgres"` | 
| `ckan.ckan.db.ckanDbName`          | Name of the database to be used by CKAN                                                                                       | `"ckan_default"` | 
| `ckan.ckan.db.ckanDbPassword`      | Password of the user for the database to be used by CKAN                                                                      | `"pass"` | 
| `ckan.ckan.db.ckanDbUrl`           | Url of the PostgreSQL server where the CKAN database is hosted                                                                | `"postgres"` | 
| `ckan.ckan.db.ckanDbUser`          | Username of the database to be used by CKAN                                                                                   | `"ckan_default"` | 
| `ckan.ckan.datastore.RoDbName`     | Name of the database to be used for Datastore                                                                                 | `"datastore_default"` | 
| `ckan.ckan.datastore.RoDbPassword` | Password for the datastore read permissions user                                                                              | `"pass"` | 
| `ckan.ckan.datastore.RoDbUrl`      | Url of the PostgreSQL server where the datastore database is hosted                                                           | `"postgres"` | 
| `ckan.ckan.datastore.RoDbUser`     | Username for the datastore database with read permissions                                                                     | `"datastorero"` | 
| `ckan.ckan.datastore.RwDbName`     | Name of the database to be used for Datastore                                                                                 | `"datastorero"` | 
| `ckan.ckan.datastore.RwDbPassword` | Password for the datastore write permissions user                                                                             | `"pass"` | 
| `ckan.ckan.datastore.RwDbUrl`      | Url of the PostgreSQL server where the datastore database is hosted                                                           | `"postgres"` | 
| `ckan.ckan.datastore.RwDbUser`     | Username for the datastore database with write permissions                                                                    | `"datastorerw"` | 

Database

| Key                                | Description                                                                                                                   | Value                    |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|--------------------------|
| `ckan.postgresql.enabled`          | Flag to control whether to deploy PostgreSQL                                                                                  | `true` | 
| `ckan.postgresql.existingSecret`   | Name of existing secret that holds passwords for PostgreSQL                                                                   | `"postgrescredentials"` | 
| `ckan.postgresql.fullnameOverride` | Name override for the PostgreSQL deployment                                                                                   | `"postgres"` | 
| `ckan.postgresql.persistence.size` | Size of the PostgreSQL pvc                                                                                                    | `"1Gi"` | 
| `ckan.postgresql.pgPass`           | Password for the master PostgreSQL user. Feeds into the `postgrescredentials` secret that is provided to the PostgreSQL chart | `"pass"` | 

To achieve a Ckan image with Keycloak SSO, we created our own image of Ckan to automatically add a Ckan extension. We made a Ckan image which installs [ckan-oauth2](https://github.com/conwetlab/ckanext-oauth2) on launching while it also configures every necessary value to configure our pre-created Ckan client on Keycloak. The added lines to the [Ckan image](https://github.com/keitaroinc/docker-ckan/tree/master/images/ckan) Dockerfile were the following:

```Docker
ENV CKAN__PLUGINS envvars image_view text_view recline_view datastore datapusher oauth2
RUN pip install --no-index --find-links=/srv/app/ext_wheels ckanext-oauth2
    # Keycloak settings
RUN paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.logout_url = /user/logged_out" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.edit_url = https://keycloak.example.test/auth/realms/datalab-demo/account" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.authorization_endpoint = https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/auth" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.token_endpoint = https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/token" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.profile_api_url = https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/userinfo" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.client_id = ckan" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.client_secret = ...secret..." && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.scope = profile email openid" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.profile_api_user_field = preferred_username" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.profile_api_mail_field = email" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.authorization_header = Bearer" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.oauth2.profile_api_fullname_field = preferred_username"
```

By default, the Keycloak's users would have the minimum privileges in the platform, so it is also required to configure these values in the image:

```Docker
    # Authorization settings
RUN paster --plugin=ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.anon_create_dataset = false" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.create_unowned_dataset = false" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.create_dataset_if_not_in_organization = false" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.user_create_groups = true" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.user_create_organizations = true" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.user_delete_groups = true" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.user_delete_organizations = true" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.create_user_via_api = false" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.create_user_via_web = false" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini -e "ckan.auth.roles_that_cascade_to_sub_groups = admin" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.auth.public_user_details = true" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.auth.public_activity_stream_detail = true" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.auth.allow_dataset_collaborators = false" && \
    paster --plugin=ckan config-tool ${APP_DIR}/production.ini "ckan.auth.create_default_api_keys = false"
```

Having the image built and published on any available platform (DockerHub, AWS ECR...) the chart's values referring it should also be set:

```yml
ckan:
  image:
    repository: <publisher>/docker-ckan
    tag: <latest | tag> 
```

Furthermore, to enable the `https` the `ingress.tls` should match the domain used in `ingress.hosts`. If the redirection of `http` to `https` is desired, the following `ingress.annotations` should be set:

```yml
ckan:
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
      nginx.ingress.kubernetes.io/preserve-trailing-slash: "true"
      kubernetes.io/ingress.allow-http: "false"
      kubernetes.io/tls-acme: "true"
```

The remainder subdependencies of Ckan are also configurable. In our case there's yet no need to do so, but the configurable values can be found in each chart's Github page:
- [Redis Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/redis)
- [Solr Bitnami Chart](https://github.com/helm/charts/tree/master/incubator/solr)
- [Datapusher Bitnami Chart](https://github.com/keitaroinc/ckan-helm/tree/master/dependency-charts/datapusher)

### PostgreSQL (Optional dependency)

For an exhaustive list on PostgreSQL configurations visit the available chart description on [Bitnami's PostgreSQL Chart](https://github.com/bitnami/charts/tree/master/bitnami/postgresql). 

As for the PostgreSQL dependency usage in this context, only the following values must be configured:

| Name                                               | Description                                                                          | Value |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | ----- |
| `postgresql.global.postgresql.postgresqlDatabase`  | PostgreSQL database (overrides `postgresqlDatabase`)                                                                        | `""`  |
| `postgresql.global.postgresql.postgresqlUsername`  | PostgreSQL username (overrides `postgresqlUsername`)                                                                        | `""`  |
| `postgresql.global.postgresql.postgresqlPassword`  | PostgreSQL admin password (overrides `postgresqlPassword`)                                                                  | `""`  |
| `postgresql.global.postgresql.servicePort`         | PostgreSQL port (overrides `service.port`                                                                                   | `""`  |
| `postgresql.persistence.size`                      | PVC Storage Request for PostgreSQL volume                                                                                   | `1Gi` |
| `postgresql.fullnameOverride`                      | String to fully override common.names.fullname template                                                                     | `""`  |
| `postgresql.postgresqlPostgresPassword`            | PostgreSQL admin password (used when `postgresqlUsername` is not `postgres`, in which case`postgres` is the admin username) | `""`  |
| `postgresql.initdbScriptsSecret`                   | Secret with scripts to be run at first boot (in case it contains sensitive information)                                     | `""`  |
| `postgresql.initdbUser`                            | Specify the PostgreSQL username to execute the initdb scripts                                                               | `""`  |
| `postgresql.initdbPassword`                        | Specify the PostgreSQL password to execute the initdb scripts                                                               | `""`  |

The `initdbScript` to be run while the instance is launching, should create all databases, users and set the users' priviledges to enable all services to run smoothly. It should set:
- a Database, User, Password and Grants for Keycloak 
- a Database, User, Password and Grants for Ckan (Master) 
- a Database, User, Password and Grants for Ckan (Default) 
- a Database, Users, Passwords and Grants for Datastore (Read and Write users)

The following code demonstrates how to do so for either of the previous points: 
```bash
#!/bin/sh
psql postgresql://postgres:{{.Values.postgresql.postgresqlPostgresPassword}}@localhost:5432/user << EOF
    CREATE DATABASE keycloak WITH ENCODING 'UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8';
    CREATE USER keycloak WITH ENCRYPTED PASSWORD 'keycloak';
    GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
  EOF
```

Having the PostgreSQL instance ready, the referent chart's values should also match the ones used in the PostgreSQL instance launching. Not only the `DBHost` variable but also all the users, passwords and database dependencies disabled.
