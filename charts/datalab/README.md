# Data Lab Helm Chart based on Onyxia, Keycloak, and MinIO&reg;

- [Onyxia](https://github.com/InseeFrLab/onyxia) is a web app that aims at being the glue between multiple open source backend technologies to provide a state of art working environnement for data scientists. Onyxia is developed by the French National institute of statistic and economic studies (INSEE).
- [Keycloak](https://www.keycloak.org/) is a high performance Java-based identity and access management solution. It lets developers add an authentication layer to their applications with minimum effort.
- [MinIO&reg;](https://min.io/) is an object storage server, compatible with Amazon S3 cloud storage service, mainly used for storing unstructured data (such as photos, videos, log files, etc.).


**Disclaimer**: All software products, projects and company names are trademark&trade; or registered&reg; trademarks of their respective holders, and use of them does not imply any affiliation or endorsement. MinIO&reg; is licensed under GNU AGPL v3.0.

## TL;DR
```
git clone https://github.com/eurostat/datalab
```

**IMPORTANT**: create your own `values.yaml` based on the default `values.yaml` with your domain name, SMTP server, and passwords.

> **ATTENTION** ensure you do not commit your `values.yaml` with secrets to the SCM.

```
cd datalab/charts/datalab
helm upgrade --install datalab . -f values.yaml --wait
```

## Introduction

This Chart wraps the necessary services to launch a complete data lab on a [Kubernetes](https://kubernetes.io/) cluster using [Helm](https://helm.sh/) package manager. It provisions the central component of the data lab [Onyxia](https://github.com/InseeFrLab/onyxia), and the necessary peripheral components to handle IAM and Storage, [Keycloak](https://www.keycloak.org/) and [MinIO&reg;](https://min.io/).

## Prerequisites

This Chart has the prerequisistes explained in the [docs](../docs/DEPLOYMENT.md):
- Kubernetes 1.12+
- Helm 3
- (RECOMMENDED) PV provisioner support in the underlying infrastructure
- Ingress controller
- Domain name and records pointing to the ingress controller
- (RECOMMENDED) wildcard TLS certificate configured for the ingress controller
- (OPTIONAL) SMTP server for user `Forgot password?` interactions and admin user account imposed actions

## Dependencies

The dependencies of the Chart are the components of the data lab with:
- [Onyxia InseeFrLab Chart](https://github.com/InseeFrLab/helm-charts/tree/master/charts/onyxia) which needs extensive configuration in the `values.yaml`.
- [Keycloak Codocentric Chart](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak) which has subdependency [PostgreSQL Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/postgresql) with **recommended** configuration to use PV.
- [MinIO&reg; Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/minio) which has **recommended** PV dependency.

## Installing the Chart

**IMPORTANT**: create your own `values.yaml` based on the default `values.yaml` with your domain name, SMTP server, and passwords.
```
cd datalab/charts/datalab
helm upgrade --install datalab . -f values.yaml --wait
```

## Uninstalling the Chart
This will delete the whole Chart. However, keep in mind that launched services during the utilization of the data lab will still be running. You will have to delete them from the user's namespaces.
```
helm uninstall datalab
```

## Configurable Parameters

### Global

| Name                |  Description                                                                                | Value              |
| ------------------- | ------------------------------------------------------------------------------------------- | ------------------ |
| domainName          | **REQUIRED** Your owned domain name which will serve as root for the generated sub-domains. | `""`               |
| smtpServer          | Configuration for Keycloak to connect to your SMTP server.                                  | `""`               |

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
| `onyxia.serviceAccount.create`       | Service account creation for the pods.                        | `true`                |
| `onyxia.serviceAccount.clusterAdmin` | ClusterRoleBinding for Onyxia API pod, needed for multi-user. | `false`               |
| `onyxia.ingress.enabled`             | Ingress resource enabled.                                     | `false`               |
| `onyxia.ingress.annotations`         | Ingress annotations.                                          | `{}`                  |
| `onyxia.ingress.hosts`               | Ingress resource hosts list.                                  | See below             |
| `onyxia.ingress.hosts[0].host`       | Ingress resource host.                                        | `chart-example.local` |
| `onyxia.ingress.hosts[0].secretName` | TLS secret name.                                              | `""`                  |

Values for Onyxia UI:

| Name                          |  Description                                                         | Value                  |
| ----------------------------- | -------------------------------------------------------------------- | ---------------------- |
| `onyxia.ui.name`              | Pod name building component.                                         | `ui`                   |
| `onyxia.ui.replicaCount`      | Number of replicas, since Onyxia is stateless.                       | `1`                    |
| `onyxia.ui.image.name`        | Image name for Onyxia Web.                                           | `inseefrlab/onyxia-web`|
| `onyxia.ui.image.version`     | Image version, keep to latest to ensure compabilities with Catalogs. | `latest`               |
| `onyxia.ui.image.pullPolicy`  | Pull policy to keep the image up to date.                            | `Always`               |
| `onyxia.ui.podSecurityContext`| Pod security context.                                                | `{}`                   |
| `onyxia.ui.securityContext`   | Container security context.                                          | `{}`                   |
| `onyxia.ui.service.type`      | Pod exposure service type.                                           | `ClusterIP`            |
| `onyxia.ui.service.port`      | Pod exposure service port.                                           | `80`                   |
| `onyxia.ui.resources`         | Pod resources requests and limitations.                              | `{}`                   |
| `onyxia.ui.nodeSelector`      | Node selector.                                                       | `{}`                   |
| `onyxia.ui.tolerations`       | Pod tolerations.                                                     | `[]`                   |
| `onyxia.ui.affinity`          | Pod affinity, e.g., use anti afinity with `replicaCount > 1`.        | `{}`                   |
| `onyxia.ui.env`               | Pod environment variables. Required to set some **(1)**              | `{}`                   |

**(1)** Onyxia UI environment variables to set are as follows in the example with your own domain name to enable OIDC and MINIO access:
```yaml
      OIDC_REALM: datalab-demo
      OIDC_CLIENT_ID: onyxia-client
      OIDC_URL: https://keycloak.example.test/auth
      MINIO_URL: https://minio.example.test
```


Values for Onyxia API:

| Name                            |  Description                                                        | Value                  |
| ------------------------------- | ------------------------------------------------------------------- | ---------------------- |
| `onyxia.api.name`               | Pod name building component.                                        | `api`                  |
| `onyxia.api.replicaCount`       | Number of replicas, since Onyxia is stateless.                      | `1`                    |
| `onyxia.api.image.name`         | Image name.                                                         | `inseefrlab/onyxia-api`|
| `onyxia.api.image.version`      |Image version, keep to latest to ensure compabilities with Catalogs. | `latest`               |
| `onyxia.api.image.pullPolicy`   | Pull policy to keep the image up to date.                           | `Always`               |
| `onyxia.api.podSecurityContext` | Pod security context.                                               | `{}`                   |
| `onyxia.api.securityContext`    | Container security context.                                         | `{}`                   |
| `onyxia.api.service.type`       | Pod exposure service type.                                          | `ClusterIP`            |
| `onyxia.api.service.port`       | Pod exposure service port.                                          | `80`                   |
| `onyxia.api.resources`          | Pod resources requests and limitations.                             | `{}`                   |
| `onyxia.api.nodeSelector`       | Node selector.                                                      | `{}`                   |
| `onyxia.api.tolerations`        | Pod tolerations.                                                    | `[]`                   |
| `onyxia.api.affinity`           | Pod affinity, e.g., use anti afinity with `replicaCount > 1`.       | `{}`                   |
| `onyxia.api.env`                | Pod environment variables. Required to set some **(2)**.            | `{}`                   |
| `onyxia.api.regions`            | Region configuration for this Onyxia API **(3)**.                   | `[]`                   |
| `onyxia.api.catalogs`           | Catalogs of services to launch for this Onyxia API **(4)**.         | `[]`                   |

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
      "monitoring": { "URLPattern": "https://graphana.example.com/<path/to/your/dashboard>?orgId=1&refresh=5s&var-namespace=$NAMESPACE&var-instance=$INSTANCE" },
      "cloudshell": {
        "catalogId": "inseefrlab-helm-charts-datascience",
        "packageName": "cloudshell"
      },
    },
    "data": { 
      "S3": { 
        "URL": "https://minio.example.test", 
        "monitoring": { 
          "URLPattern": "https://graphana.example.com/<path/to/your/dashboard>?orgId=1&var-username=$BUCKET_ID"
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

| Name                                          |  Description                                                                    | Value                                      |
| --------------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------ |
| `keycloak.replicas`                           | The number of replicas to create                                                | `1`                                        |
| `keycloak.extraEnv`                           | Additional environment variables for Keycloak                                   | `""`                                       |
| `keycloak.rbac.create`                        | Specifies whether RBAC resources are to be created                              | `false`                                    |
| `keycloak.rbac.rules`                         | Custom RBAC rules, e. g. for KUBE_PING                                          | `[]`                                       |
| `keycloak.extraVolumes`                       | Add additional volumes, e.g., realm configuration                               | `""`                                       |
| `keycloak.extraVolumeMounts`                  | Add additional volumes mounts, e.g., realm configuration                        | `""`                                       |
| `keycloak.affinity`                           | Pod affinity                                                                    | Hard node and soft zone anti-affinity      |
| `keycloak.ingress.enabled`                    | If `true`, an Ingress is created                                                | `false`                                    |
| `keycloak.ingress.rules`                      | List of Ingress Ingress rule                                                    | see below                                  |
| `keycloak.ingress.rules[0].host`              | Host for the Ingress rule                                                       | `{{ .Release.Name }}.keycloak.example.com` |
| `keycloak.ingress.rules[0].paths`             | Paths for the Ingress rule                                                      | see below                                  |
| `keycloak.ingress.rules[0].paths[0].path`     | Path for the Ingress rule                                                       | `/`                                        |
| `keycloak.ingress.rules[0].paths[0].pathType` | Path Type for the Ingress rule                                                  | `Prefix`                                   |
| `keycloak.ingress.servicePort`                | The Service port targeted by the Ingress                                        | `http`                                     |
| `keycloak.ingress.annotations`                | Ingress annotations                                                             | `{}`                                       |

The value `keycloak.extraEnv`, if using a more than one replica, should also include a node discovery method, e.g., `KUBE_PING` as indicated by the Chart providers in the [documentation](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak#kube_ping-service-discovery).

PostgreSQL sub-dependency parameters to be set are:

| Name                                     |  Description                                            | Value      |
| ---------------------------------------- | ------------------------------------------------------- | ---------- |
| `keycloak.postgresql.enabled`            | If `true`, the Postgresql dependency is enabled         | `true`     |
| `keycloak.postgresql.postgresqlUsername` | Value for PostgreSQL username                           | `keycloak` |
| `keycloak.postgresql.postgresqlPassword` | Value for PostgreSQL password                           | `keycloak` |
| `keycloak.postgresql.postgresqlDatabase` | PostgreSQL Database to create                           | `keycloak` |


### MinIO&reg;
For an exhaustive list on MinIO&reg; configurations visit the available documentation on [MinIO&reg; Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/minio).

Generic 

| Name                        |  Description                                           | Value        |
| --------------------------- | ------------------------------------------------------ | ------------ |
| `minio.enabled`             | Enable for Keycloak to create a client for MinIO&reg;  | `true`       |
| `minio.mode`                | MinIO&reg; server mode (`standalone` or `distributed`) | `standalone` |
| `minio.accessKey.password`  | Root user access key.                                  | `""`         |
| `minio.secretKey.password`  | Root user secret key.                                  | `""`         |
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
| `minio.ingress.annotations`    | Additional annotations for the Ingress resource.     | `{}`                     |
| `minio.apiIngress.enabled`     | Enable API ingress controller resource               | `false`                  |
| `minio.apiIngress.hostname`    | Default host for the API ingress resource            | `minio.local`            |
| `minio.apiIngress.annotations` | Additional annotations for the API Ingress resource. | `{}`                     |
