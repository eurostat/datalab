# Data Lab Helm Chart based on Onyxia, Keycloak, MinIO&reg;, HashiCorp's Vault, Ckan, Prometheus, Grafana and Apache Superset

- [Onyxia](https://github.com/InseeFrLab/onyxia) is a web app that aims at being the glue between multiple open source backend technologies to provide a state of art working environnement for data scientists. Onyxia is developed by the French National institute of statistic and economic studies (INSEE).
- [Keycloak](https://www.keycloak.org/) is a high performance Java-based identity and access management solution. It lets developers add an authentication layer to their applications with minimum effort.
- [MinIO&reg;](https://min.io/) is an object storage server, compatible with Amazon S3 cloud storage service, mainly used for storing unstructured data (such as photos, videos, log files, etc.).
- [HashiCorp's Vault](https://www.vaultproject.io/) is a secrets manager build by HashiCorp to secure, store and tightly control access to tokens, passwords, certificates, encryption keys for protecting secrets and other sensitive data using a UI, CLI, or HTTP API.
- [Prometheus](https://prometheus.io/) is a metrics collector and alert manager component.
- [Grafana](https://grafana.com/) is an observability tool to add value to the collected metrics.
- [Ckan](https://ckan.org/) is a data management system. For the purpose of this project it will be used as a data catalog.
- (OPTIONAL) [PostgreSQL](https://www.postgresql.org/) is a powerful, open source object-relational database system with over 30 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.
- (OPTIONAL) [Redis](https://redis.io/) is an open source (BSD licensed), in-memory data structure store, used as a database, cache, and message broker. In the context of this project ,Redis is a subdependency of various non optional charts, so it made sense to have the option of having a single central instance for it. 
- [Apache Superset](https://superset.apache.org/) is a modern data exploration and visualization platform. For the purpose of this project it will be used as the main data visualization tool to share dashboards between users. 
- [Gitlab](https://about.gitlab.com/) is a DevOps platform. It helps to deliver software faster with better security and collaboration in a single platform. In this project, Gitlab will serve as git collaboration tool with DevOps features available.



**Disclaimer**: All software products, projects and company names are trademark&trade; or registered&reg; trademarks of their respective holders, and use of them does not imply any affiliation or endorsement. Keycloak is licensed under Apache License v2.0. MinIO&reg; is licensed under GNU AGPL v3.0. HashiCorp's Vault Chart is licensed under MPL-2.0 License. Grafana is licensed under GNU AGPL v3.0. Prometheus is licensed under Apache License v2.0. Ckan is licensed under GNU AGPL v3.0. Redis is BSD licensed and Gitlab is MIT licensed.

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

## Introduction

This Chart wraps the necessary services to launch a complete data lab on a [Kubernetes](https://kubernetes.io/) cluster using [Helm](https://helm.sh/) package manager. It provisions the central component of the data lab [Onyxia](https://github.com/InseeFrLab/onyxia), and the necessary peripheral components to handle IAM ([Keycloak](https://www.keycloak.org/)), Storage ([MinIO&reg;](https://min.io/)), Secrets Management ([HashiCorp's Vault](https://www.vaultproject.io/)), Monitoring ([Prometheus](https://prometheus.io/)+[Grafana](https://grafana.com/)), Data Catalog ([Ckan](https://ckan.org/)), Data exploration and visualization ([Apache Superset](https://superset.apache.org/)) and Collaboration/DevOps ([Gitlab](https://about.gitlab.com/)).

## Prerequisites

This Chart has the prerequisistes explained in the [docs](../../docs/DEPLOYMENT.md):
- Kubernetes 1.20
- Helm 3
- PV provisioner support in the underlying infrastructure
- Ingress controller
- Domain name and records pointing to the ingress controller
- (RECOMMENDED) wildcard TLS certificate configured for the ingress controller
- (RECOMMENDED) SMTP server for automated messages and authentication methods configuration in Keycloak
- (OPTIONAL) Ckan image with SSO configuration (Ckan extension + Keycloak Client definition)
- (OPTIONAL) Keycloak metrics side car image (to measure user activity based on Keycloak events)
- (OPTIONAL) User notification container image (to notify users of their own alerts)

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
- [Prometheus Community Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus) with necessary additional configurations in metric labels, alerts, and alert routing.
- [Grafana Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana) with pre-built dashboards for the platform monitoring, with Prometheus as the data source.
- [Apache Superset Chart](https://github.com/apache/superset/tree/master/helm/superset) which has subdependency [Redis Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/redis) and [PostgreSQL Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/postgresql) with **recommended** configuration to use PV.
- [Gitlab Chart](https://about.gitlab.com/) also with a few dependencies which include:
  - [Redis Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/redis)
  - [PostgreSQL Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/postgresql) with PostgreSQL version 12 or higher.
  - [MinIO&reg; Bitnami Chart](https://github.com/bitnami/charts/tree/master/bitnami/minio)
  - [Ingress-Nginx Chart](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx)

While on the topic of dependencies, it is relevant to state a few considerations needed for the chart to be able to install with no collisions when Gitlab is enabled. Gitlab does not limit its variables' values to be within the ``gitlab`` tag confines, instead, it uses any value within the ``global`` confines of the values file. To bypass this issue, we opted to attribute ``alias`` to MinIO&reg;, Prometheus, PostgreSQL and Redis, in order to make Gitlab ignore this values. Any ``alias`` different from the default will suffice.

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

| Name                        |  Description                                                                                    | Value              |
| --------------------------- | ----------------------------------------------------------------------------------------------- | ------------------ |
| `domainName`                | **REQUIRED** Your owned domain name which will serve as root for the generated sub-domains      | `""`               |
| `smtpServer`                | Configuration for Keycloak to connect to your SMTP server **(1)**                               | `""`               |
| `autoUpdatePolicy.schedule` | Schedule for the MinIO update policy cronjob to run                                             | `"* */12 * * *"`   |
| `userNotification`          | Configuration of a deployment and service to forward user notifications based on alerts **(2)** | `{}`               |

**(1)** The SMTP server configuration format would be:
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

**(2)** The `userNotification` values have to take into consideration the HTTP POST request sent from Prometheus Alert Manager [configured webhook](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config) in the Alert Manager files, found in the value `prometheus.alertmanagerFiles.alertmanager.yml` in the Chart. An image example to be used is described in [here](../../images/user-notification-container). The configuration, given an SMTP server, should be similar to the following example:
```yaml
userNotification:
  enabled: true
  service:
    annotations: {}
    labels: {}
    webhookPort: 9992
  deployment:
    annotations: {}
    labels: {}
    podAnnotations: {}
    podLabels: {}
    containerImage: <your-image>
    imagePullPolicy: Always
    ports: |
      - containerPort: 9992
        name: notify-users
        protocol: TCP
    extraEnv: |
      - name: KEYCLOAK_SC__SVC_NAME
        value: http://{{ .Release.Name }}-keycloak-http.default.svc.cluster.local:80
      - name: KEYCLOAK_ADMIN_USERNAME
        value: ""
      - name: KEYCLOAK_ADMIN_PASSWORD
        value: ""
      - name: SMTP_USERNAME
        value: ""
      - name: SMTP_PASSWORD
        value: ""
      - name: SMTP_SERVER
        value: ""
      - name: SMTP_SERVER_PORT
        value: ""
```

Values for a demonstration with pre-configured users and projects (user groups):

| Name                       |  Description                                                                    | Value               |
| -------------------------- | ------------------------------------------------------------------------------- | ------------------- |
| `demo`                     | Configuration block to set-up demo users and groups during the deployment       | see below           |
| `demo.enabled`             | Enable the demo block configuration                                             | `true`              |
| `demo.users`               | List of users to use in the demo                                                | see below           |
| `demo.users[0].name`       | Name of a demo user                                                             | `jondoe`            |
| `demo.users[0].password`   | Password of a demo user                                                         | `jondoe`            |
| `demo.users[0].groups`     | Groups/projects of a demo user                                                  | `[g1, g2]`          |
| `demo.projects`            | List of projects (user groups) to use in the demo                               | see below           |
| `demo.projects[0].name`    | Name of a demo project                                                          | `g1`                |
| `demo.projects[0].members` | List of members of a demo project                                               | `[jondoe, janedoe]` |

Values for the alert thresholds that will influence the rules in [this file](./templates/prometheus-rules-cm.yaml), with an informed decision about [Requests and Limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) and your own cluster resources:

| Name                               |  Description                                                                                    | Value       |
| ---------------------------------- | ----------------------------------------------------------------------------------------------- | ----------- |
| `alertThresholds`                  | Configuration block to set-up alert thresholds for the Prometheus rules                         | see below   |
| `alertThresholds.inactivityPeriod` | Period, e.g. in days (`d`), in which no user activity will indicate a user is inactive          | `15d`       |
| `alertThresholds.CpuRequestQuota`  | Soft quota (i.e., an alert) for CPU cores resource request per user                             | `0.5`       |
| `alertThresholds.MemRequestQuota`  | Soft quota (i.e., an alert) for GB of memory resource request per user                          | `4`         |
| `alertThresholds.CpuLimitsQuota`   | Soft quota (i.e., an alert) for CPU cores resource limit per user                               | `30`        |
| `alertThresholds.MemLimitsQuota`   | Soft quota (i.e., an alert) for GB of memory resource limit per user                            | `64`        |

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
      VAULT_URL: https://vault.example.test
      REACT_APP_DATA_CATALOG_URL: ckan
      REACT_APP_DOMAIN_URL: example.test
      REACT_APP_EXTRA_LEFTBAR_ITEMS: |
        {
          "links": 
          [
            {
              "label": { "en": "My Data Visualization Tool", "fr": "Outil de visualisation de donn\u00e9es" },
              "iconId": "SsidChart",
              "url": "https://apache-superset.example.test",
            },{
              "label": { "en": "My Data Catalog", "fr": "Mes catalogue de donn\u00e9es" },
              "iconId": "MenuBookOutlined",
              "url": "https://ckan.example.test",
            }
          ]
        }
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
| `keycloak.rbac.rules`                         | Custom RBAC rules, e.g. for KUBE_PING                                           | `[]`                                       |
| `keycloak.extraVolumes`                       | Add additional volumes, e.g. realm configuration                                | `""`                                       |
| `keycloak.extraVolumeMounts`                  | Add additional volumes mounts, e.g. realm configuration                         | `""`                                       |
| `keycloak.extraInitContainers`                | Add additional init containers, e.g. `keycloak-metrics-spi`                     | `""`                                       |
| `keycloak.extraContainers`                    | Add additional side car containers, e.g. custom metrics container               | `""`                                       |
| `keycloak.affinity`                           | Pod affinity                                                                    | Hard node and soft zone anti-affinity      |
| `keycloak.service`                            | Service definition (e.g. add annotations for Prometheus scrapping)              | see bellow                                 |

The value `keycloak.extraEnv` will hold a lot of information to configure the Keycloak deployment, for example:
- If using a more than one replica, should also include a node discovery method, e.g. `KUBE_PING` as indicated by the Chart providers in the [documentation](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak#kube_ping-service-discovery).
- To connect to a database `DB_VENDOR`, `DB_ADDR`, `DB_PORT`, `DB_DATABASE`, `DB_USER`, and `DB_PASSWORD` are necessary
- If you want metrics, pushed to Prometheus it is necessary to indicate a `PROMETHEUS_PUSHGATEWAY_ADDRESS` (and also proceed with the `keycloak-metrics-spi` in the `extraInitContainers`)

Another addition that can be made is to add a sidecar container to expose Keycloak metrics to a Prometheus scrapper. An example image can be built from this [Dockerfile](../../images/keycloak-metrics-sidecar), and it is necessary to set both the `extraContainer` and the service annotations, for example:
```yaml
extraContainers: |
  - name: keycloak-event-metrics-sidecar
    image: <your-image>
    imagePullPolicy: IfNotPresent
    env:
      - name: KEYCLOAK_SC__SVC_NAME
        value: http://localhost:8080
      - name: KEYCLOAK_ADMIN_USERNAME
        value: TODO
      - name: KEYCLOAK_ADMIN_PASSWORD
        value: TODO
    ports:
      - containerPort: 9991
        name: event-sidecar
        protocol: TCP

service:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9991"
    prometheus.io/path: "metrics"
```


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


PostgreSQL sub-dependency can be disabled and a common PostgreSQL database can be used:

| Name                                     |  Description                                            | Value      |
| ---------------------------------------- | ------------------------------------------------------- | ---------- |
| `keycloak.postgresql.enabled`            | If `true`, the Postgresql dependency is enabled         | `false`    |


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
| `minio.defaultBuckets`            | MinIO&reg; default buckets to create on instalation                             | `""`         |

The value for `minio.extraEnv`, if using Keycloak SSO should contain the following (with your domain instead of `example.test`):

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
| `prometheus.server.extraConfigmapMounts`             | List of configmap mounts for Prometheus Server                          | `[]`                          |
| `prometheus.configmapReload`                         | Configuration block for configmap reload sidecar                        | See Below                     |
| `prometheus.alertmanagerFiles`                       | Configmap entries for Alertmanager                                      | alertmanager.yml              |
| `prometheus.serverFiles`                             | Configmap entries for Prometheus Server configurations                  | See Below                     |
| `prometheus.kubeStateMetrics`                        | [KubeStateMetrics](https://github.com/kubernetes/kube-state-metrics) enable block | See Below           |
| `prometheus.kubeStateMetrics.enabled`                | To enable the KubeStateMetrics agent                                            | `true`                |
| `prometheus.kube-state-metrics`                      | [KubeStateMetrics](https://github.com/kubernetes/kube-state-metrics) configuration block | See [here](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics)    |


It is recommended to configure the Alertmanager, it can be done through the `alertmanagerFiles`, with more information on configuration available on the [Official Documentation](https://prometheus.io/docs/alerting/latest/configuration/). In the example configuration an email and a webhook (based on the [userNotification endpoint](#global)) are the default receivers of any alert that is triggered:

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
          webhook_configs:
            - url: http://datalab-user-notification.default.svc.cluster.local:9992/webhook # your userNotification endpoint
              send_resolved: false
      templates: []
```

It is also recommended to create [alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) to send to the receiver to ensure proper usage of the platform, for example, to supervise users' resource consumption in Onyxia there are a set of rules in the [prometheus-configmap](./templates/prometheus-rules-cm.yaml), which is then mounted (and reloaded in case of any changes) through the configurations in both `server` and `configmapReload`:
```yaml

  server:
    enabled: true   
    extraConfigmapMounts:
      - name: prometheus-alerts
        mountPath: /etc/config/alerts
        configMap: prometheus-alerts
        readOnly: true
        
  configmapReload:
    prometheus:
      extraConfigmapMounts:
        - name: prometheus-alerts
          mountPath: /etc/alerts
          configMap: prometheus-alerts
          readOnly: true
      extraVolumeDirs:
        - /etc/alerts
        
  serverFiles:
    prometheus.yml:
      rule_files:
        - /etc/config/rules/*.yml
        - /etc/config/alerts/*.yml

```

Finally, the `kube-state-metrics` configuration block can allow labels from `pods`to be used in monitoring queries. For example:
```yaml
  kube-state-metrics:
    metricLabelsAllowlist:
      - pods=[*]
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

| Key                                | Description                                                                          | Value                    |
|------------------------------------|--------------------------------------------------------------------------------------|--------------------------|
| `ckan.clientsecret`                | Client secret for CKAN Oauth client                                                  | `""`                     | 
| `ckan.image.pullPolicy`            | Pull policy to keep the image up to date                                             | `"IfNotPresent"`         | 
| `ckan.image.repository`            | Image to pull                                                                        | `"keitaro/ckan"`         | 
| `ckan.image.tag`                   | Tag of image to pull                                                                 | `"2.9.2"`                |  
| `ckan.DBDeploymentName`            | Variable for name override for postgres deployment                                   | `"postgres"`             |
| `ckan.DBHost`                      | Variable for name of headless svc from postgres deployment                           | `"postgres"`             |
| `ckan.MasterDBName`                | Variable for name of the master user database in PostgreSQL                          | `"ckan"`                 | 
| `ckan.MasterDBPass`                | Variable for password for the master user in PostgreSQL                              | `"pass"`                 | 
| `ckan.MasterDBUser`                | Variable for master user name for PostgreSQL                                         | `"postgres"`             | 
| `ckan.CkanDBName`                  | Variable for name of the database used by CKAN                                       | `"ckan_default"`         | 
| `ckan.CkanDBPass`                  | Variable for password for the CKAN database owner                                    | `"pass"`                 | 
| `ckan.CkanDBUser`                  | Variable for username for the owner of the CKAN database                             | `"ckan_default"`         | 
| `ckan.DatastoreDBName`             | Variable for name of the database used by Datastore                                  | `"datastore_default"`    | 
| `ckan.DatastoreRODBPass`           | Variable for password for the datastore database user with read access               | `"pass"`                 | 
| `ckan.DatastoreRODBUser`           | Variable for username for the user with read access to the datastore database        | `"datastorero"`          | 
| `ckan.DatastoreRWDBPass`           | Variable for password for the datastore database user with write access              | `"pass"`                 | 
| `ckan.DatastoreRWDBUser`           | Variable for username for the user with write access to the datastore database       | `"datastorerw"`          | 

Network

| Key                                | Description                              | Value                    |
|------------------------------------|------------------------------------------|--------------------------|
| `ckan.ingress.annotations`         | Ingress annotations                      | `{}`                     | 
| `ckan.ingress.enabled`             | Ingress enablement                       | `true`                   | 
| `ckan.ingress.hosts[0].host`       | Ingress resource hosts list              | `"chart-example.local"`  |
| `ckan.ingress.hosts[0].paths`      | Ingress resource hosts' path list        | `[/]`                    |
| `ckan.ingress.tls[0].hosts`        | Ingress resource tls hosts list          | `"chart-example.local"`  |

Ckan Specifications

| Key                                | Description                                                                                   | Value                    |
|------------------------------------|-----------------------------------------------------------------------------------------------|--------------------------|
| `ckan.ckan.siteUrl`                | Url for the CKAN instance                                                                     | `"http://localhost:5000"`| 
| `ckan.ckan.psql.initialize`        | Flag whether to initialize the PostgreSQL instance with the provided users and databases      | `true`                   | 
| `ckan.ckan.psql.masterDatabase`    | PostgreSQL database for the master user                                                       | `"postgres"`             | 
| `ckan.ckan.psql.masterPassword`    | PostgreSQL master user password                                                               | `"pass"`                 | 
| `ckan.ckan.psql.masterUser`        | PostgreSQL master username                                                                    | `"postgres"`             | 
| `ckan.ckan.db.ckanDbName`          | Name of the database to be used by CKAN                                                       | `"ckan_default"`         | 
| `ckan.ckan.db.ckanDbPassword`      | Password of the user for the database to be used by CKAN                                      | `"pass"`                 |  
| `ckan.ckan.db.ckanDbUrl`           | Url of the PostgreSQL server where the CKAN database is hosted                                | `"postgres"`             | 
| `ckan.ckan.db.ckanDbUser`          | Username of the database to be used by CKAN                                                   | `"ckan_default"`         | 
| `ckan.ckan.datastore.RoDbName`     | Name of the database to be used for Datastore                                                 | `"datastore_default"`    | 
| `ckan.ckan.datastore.RoDbPassword` | Password for the datastore read permissions user                                              | `"pass"`                 | 
| `ckan.ckan.datastore.RoDbUrl`      | Url of the PostgreSQL server where the datastore database is hosted                           | `"postgres"`             | 
| `ckan.ckan.datastore.RoDbUser`     | Username for the datastore database with read permissions                                     | `"datastorero"`          | 
| `ckan.ckan.datastore.RwDbName`     | Name of the database to be used for Datastore                                                 | `"datastorero"`          | 
| `ckan.ckan.datastore.RwDbPassword` | Password for the datastore write permissions user                                             | `"pass"`                 | 
| `ckan.ckan.datastore.RwDbUrl`      | Url of the PostgreSQL server where the datastore database is hosted                           | `"postgres"`             | 
| `ckan.ckan.datastore.RwDbUser`     | Username for the datastore database with write permissions                                    | `"datastorerw"`          | 

Database

| Key                                | Description                                                                                                                   | Value                    |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|--------------------------|
| `ckan.postgresql.enabled`          | Flag to control whether to deploy PostgreSQL                                                                                  | `true`                   | 
| `ckan.postgresql.existingSecret`   | Name of existing secret that holds passwords for PostgreSQL                                                                   | `"postgrescredentials"`  | 
| `ckan.postgresql.fullnameOverride` | Name override for the PostgreSQL deployment                                                                                   | `"postgres"`             | 
| `ckan.postgresql.persistence.size` | Size of the PostgreSQL pvc                                                                                                    | `"1Gi"`                  | 
| `ckan.postgresql.pgPass`           | Password for the master PostgreSQL user. Feeds into the `postgrescredentials` secret that is provided to the PostgreSQL chart | `"pass"`                 | 

To achieve a Ckan image with Keycloak SSO, we created our own image of Ckan to automatically add a Ckan extension. We made a Ckan image which installs [ckan-oauth2](https://github.com/conwetlab/ckanext-oauth2) on launching while it also configures every necessary value to configure our pre-created Ckan client on Keycloak. The added lines to the [Ckan image](https://github.com/keitaroinc/docker-ckan/tree/master/images/ckan) Dockerfile were the following:

```Dockerfile
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

```Dockerfile
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

| Name                                               | Description                                                                                                                 | Value |
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
- a Database, User, Password and Grants for Superset 
- a Database, User, Password and Grants for Gitalab (including user as superuser) 

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


### Superset

Superset is a dependency of this Chart, created with the [Offical Superset Helm Chart](https://github.com/apache/superset/tree/master/helm/superset). Since there is already a database in the cluster it is possible to use that one as Superset backend database, however it is also possible to customize your own PostgreSQL sub-dependency from superset (more information at the Superset [values.yaml](https://github.com/apache/superset/blob/master/helm/superset/values.yaml)). The used values on this Chart are the following:

| Key                                | Description                                                              | Value                        |
|------------------------------------|--------------------------------------------------------------------------|------------------------------|
| `superset.enable`                  | Enable Superset sub Chart to be launched with the rest                   | `true`                       | 
| `superset.clientsecret`            | Client secret for the OAuth 2.0 server-side client with Keycloak         | `your-client-secret`         | 
| `superset.flasksecret`             | Flask secret used in signing cookies                                     | `your-flask-secret`          | 
| `superset.configSSO`               | Your Keycloak ingress (or DNS)                                           | `keycloak.example.test`      | 
| `superset.supersetNode`            | Configuration of the superset node                                       | See below **(1)**            | 
| `superset.postgresql.enabled`      | To enable the PostgreSQL sub-dependency                                  | `false`                      | 
| `superset.redis.enable`            | To enable the Redis sub-dependency Chart                                 | `true`                       | 
| `superset.redis.redisHost`         | To name the host of the launched Redis in sub-dependency                 | `datalab-redis-headless`     | 
| `superset.redis.usePassword`       | Flag to use password in Redis authentication                             | `false`                      | 
| `superset.extraConfigs`            | Extra configurations to be applied to Superset (e.g., allow uploads)     | See below **(2)**            | 
| `superset.extraSecrets`            | Extra Secrets to mount as drives                                         | See below **(3)**            | 
| `superset.configOverrides`         | Superset configuration overrides (e.g., authentication method)           | See below **(3)**            | 
| `superset.extraVolumes`            | Extra volumes to create out of secrets or configmaps (e.g., with client secrets)  | See below **(3)**   | 
| `superset.extraVolumeMounts`       | Extra volume mounts                                                      | See below **(3)**            | 
| `superset.bootstrapScript`         | Bootstrap Script to run in Superset                                      | See below **(4)**            |

**(1)** The default supersetNode configuration in this Chart assumes a pre-created PostgreSQL database and a Redis created in a sub-dependency:
```yaml
  supersetNode:
    command:
      - "/bin/sh"
      - "-c"
      - ". {{ .Values.configMountPath }}/superset_bootstrap.sh; /usr/bin/run-server.sh"
    connections:
      redis_host: datalab-redis-headless
      redis_port: "6379"
      db_host: postgres-headless
      db_port: 5432
      db_user: superset
      db_pass: superset
      db_name: superset
```

**(2)** Apache Superset can be further configured with `extraConfigs`, for example, to enable files upload it is necessary to do the following:
```yaml
  extraConfigs: 
    datasources-init.yaml: |
        databases:
        - allow_file_upload: true
          allow_ctas: true
          allow_cvas: true
          database_name: superset
          extra: "{\r\n    \"metadata_params\": {},\r\n    \"engine_params\": {},\r\n    \"\
            metadata_cache_timeout\": {},\r\n    \"schemas_allowed_for_file_upload\": []\r\n\
            }"
          sqlalchemy_uri: example://superset.local
          tables: []
```

**(3)** In order to set Keycloak as the authentication method, it is necessary to override configurations, create a [custom login flow](./templates/_superset-security-manager.tpl) for OIDC authentication, and mount the `client-secret` to use it:
```yaml
  extraSecrets:
    custom_sso_security_manager.py: |-
      {{ include "datalab.superset.securitymanager" . }}
      
  configOverrides:
    enable_oauth: |-
      {{ include "datalab.superset.enableoauth" . }}
    proxy_https: |
      ENABLE_PROXY_FIX = True
      PREFERRED_URL_SCHEME = 'https'

  extraVolumes:
    - name: clientsecret
      secret:
        secretName: "{{ .Release.Name }}-superset-client-secret"
        defaultMode: 0600

  extraVolumeMounts:
    - name: clientsecret
      mountPath: /mnt/secret
``` 

**(4)** The bootstrap script can include different libraries to make available for Superset functionning:
```yaml  
  bootstrapScript: |
    #!/bin/bash
    rm -rf /var/lib/apt/lists/* && \
    pip install \
      psycopg2-binary==2.9.1 \
      redis==3.5.3 \
      Flask-OIDC==1.3.0 && \
    if [ ! -f ~/bootstrap ]; then echo "Running Superset with uid 0" > ~/bootstrap; fi

``` 

Network

| Key                                    | Description                              | Value                            |
|----------------------------------------|------------------------------------------|----------------------------------|
| `superset.ingress.annotations`         | Ingress annotations                      | See below                        | 
| `superset.ingress.enabled`             | Ingress enablement                       | `true`                           | 
| `superset.ingress.ingressClassName`    | Ingress class name                       | `"nginx"`                        |
| `superset.ingress.path`                | Ingress resource path                    | `/  `                            |
| `superset.ingress.pathType`            | Ingress resource path type               | `ImplementationSpecific`         |
| `superset.ingress.hosts`               | Ingress resource hosts list              | `[apache-superset.example.test]` |

To run Superset behind an `nginx` ingress controller, it is recommended to have some annotations:
```yaml
  ingress:
    annotations:
        # Extend timeout to allow long running queries.
        nginx.ingress.kubernetes.io/proxy-connect-timeout: "300"
        nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
        nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
        # Take size into account for bigger file uploads
        nginx.org/client-max-body-size: "50m"
        nginx.ingress.kubernetes.io/proxy-body-size: "128m"
        # Always force https
        nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
        nginx.ingress.kubernetes.io/preserve-trailing-slash: "true"
```


### Gitlab

Gitlab is a dependency of this Chart, created with the [Offical Gitlab Helm Chart](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master). Since there is already a database in the cluster it is possible to use that one as Gitlab backend database, however it is also possible to customize your own PostgreSQL sub-dependency from gitlab (more information at the Gitlab [values.yaml](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/values.yaml)). The used values on this Chart are the following:

Global (The global properties are used to configure multiple charts at once)

PostgreSQL
| Key                                | Description                                                              | Value                        |
|------------------------------------|--------------------------------------------------------------------------|------------------------------|
| `global.edition`                  | Gitlab edition to be used                   | `"ce"`                       | 
| `global.psql.host`                  | PostgreSQL host (service)                   | `""`                       | 
| `global.psql.port`                  | PostgreSQL service port                   | `5432`                       | 
| `global.psql.database`                  | PostgreSQL database name                   | `"gitlabhq_production"`                       | 
| `global.psql.username`                  | PostgreSQL username                   | `"gitlab"`                       | 
| `global.psql.password.useSecret`                  | If PostgreSQL should use secret to load password                   | `true`                       | 
| `global.psql.password.secret`                  | Secret name with PostgreSQL password                   | See below **(1)**                       | 
| `global.psql.password.key`                  | Secret key with PostgreSQL password                   | See below **(1)**                       | 

Ingress & Hosts configurations

| Key                                | Description                                                              | Value                        |
|------------------------------------|--------------------------------------------------------------------------|------------------------------|
| `global.ingress.enabled`                  | If ingress is enabled                   | `{}`                       | 
| `global.ingress.class`                  | Ingress class                   | `"nginx"`                       | 
| `global.ingress.tls.enabled`                  | If Ingress TLS is enabled                   | `true`                       | 
| `global.ingress.tls.secretname`                  | TLS certificate secret name                   | `""`                       | 
| `global.ingress.configureCertmanager`                  | If certmanager should be installed                   | `{}`                       | 
| `global.hosts.domain`                  | Domain to host Gitlab                   | `""`                       | 
| `global.hosts.https`                  | If https is enabled                   | `{}`                       | 
| `global.hosts.gitlab.name`                  | Gitlab hostname                   | `{}`                       | 
| `global.hosts.gitlab.https`                  | If https is enabled                   | `{}`                       | 
| `global.hosts.minio.name`                  | Minio hostname                   | `{}`                       | 
| `global.hosts.minio.https`                  | If https is enabled                   | `{}`                       | 

Minio bucket configurations

| Key                                | Description                                                              | Value                        |
|------------------------------------|--------------------------------------------------------------------------|------------------------------|
| `global.mnio.enabled`                  | If Minio should be installed as Gitlab dependency                   | `{}`                       | 
| `global.registry.bucket`                  | Bucket name to store registries                   | `""`                       | 
| `global.appConfig.lfs.bucket`                  | Bucket name to store local file storage                   | `""`                       | 
| `global.appConfig.lfs.connection.secret`                  | Secret name with connection to Minio details                   | See below **(1)**                       | 
| `global.appConfig.lfs.connection.key`                  | Secret key with connection to Minio details                   | See below **(1)**                       | 
| `global.appConfig.artifacts.bucket`                  | Bucket name to store artifacts                   | `""`                       | 
| `global.appConfig.artifacts.connection.secret`                  | Secret name with connection to Minio details                   | See below **(1)**                       | 
| `global.appConfig.artifacts.connection.key`                  | Secret key with connection to Minio details                   | See below **(1)**                       | 
| `global.appConfig.uploads.bucket`                  | Bucket name to store uploads                   | `""`                       | 
| `global.appConfig.uploads.connection.secret`                  | Secret name with connection to Minio details                   | See below **(1)**                       | 
| `global.appConfig.uploads.connection.key`                  | Secret key with connection to Minio details                   | See below **(1)**                       | 
| `global.appConfig.packages.bucket`                  | Bucket name to store packages                   | `""`                       | 
| `global.appConfig.packages.connection.secret`                  | Secret name with connection to Minio details                   | See below **(1)**                       | 
| `global.appConfig.packages.connection.key`                  | Secret key with connection to Minio details                   | See below **(1)**                       | 
| `global.appConfig.backups.bucket`                  | Bucket name to store backups                   | `""`                       | 
| `global.appConfig.backups.tmpBucket`                  | Bucket name to temporary store backups                   | `""`                       | 

Omniauth

| Key                                | Description                                                              | Value                        |
|------------------------------------|--------------------------------------------------------------------------|------------------------------|
| `global.omniauth.enabled`                  | Enable / disable the use of OmniAuth with GitLab                   | `{}`                       | 
| `global.omniauth.autoSignInWithProvider`                  | Single provider name allowed to automatically sign in                   | `{}`                       | 
| `global.omniauth.syncProfileFromProvider`                  | List of provider names that GitLab should automatically sync profile information from                   | `[]`                       | 
| `global.omniauth.syncProfileAttributes`                  | List of profile attributes to sync from the provider upon login                   | `[]`                       | 
| `global.omniauth.allowSingleSignOn`                  | Enable the automatic creation of accounts when signing in with OmniAuth                   | `[]`                       | 
| `global.omniauth.blockAutoCreatedUsers`                  | If true auto created users will be blocked by default and will have to be unblocked by an administrator before they are able to sign in                   | `{}`                       | 
| `global.omniauth.autoLinkLdapUser`                  | 	Can be used if you have LDAP / ActiveDirectory integration enabled                   | `{}`                       | 
| `global.omniauth.autoLinkSamlUser`                  | 	Can be used if you have SAML integration enabled                   | `{}`                       | 
| `global.omniauth.autoLinkUser`                  | 		Allows users authenticating via an OmniAuth provider to be automatically linked to a current GitLab user if their emails match                   | `[]`                       | 
| `global.omniauth.externalProviders`                  | 			You can define which OmniAuth providers you want to be external, so that all users creating accounts, or logging in via these providers will be unable to access internal projects                   | `[]`                       | 
| `global.omniauth.allowBypassTwoFactor`                  | 	Allows users to log in with the specified providers without two factor authentication | `[]`                       | 
| `global.omniauth.providers.secret`                  | 	The secret name containing the provider block | See below **(1)**                       | 
| `global.omniauth.providers.key`                  | 	The secret key containing the provider block | See below **(1)**                       | 
| `global.initialDefaults.signupEnabled`                  | 	If the registering new accounts should be enabled | `{}`                       | 

Incoming & Service Desk Emails

| Key                                | Description                                                              | Value                        |
|------------------------------------|--------------------------------------------------------------------------|------------------------------|
| `global.incomingEmail.enabled`                  | If incoming email should be enabled                    | `{}`                       | 
| `global.incomingEmail.address`                  | Incoming email address                    | `""`                       | 
| `global.incomingEmail.host`                  | Incoming email host                    | `""`                       | 
| `global.incomingEmail.port`                  | Incoming email port                    | `""`                       | 
| `global.incomingEmail.ssl`                  | If incoming email ssl enabled                    | `{}`                       | 
| `global.incomingEmail.startTls`                  | If incoming email startTls enabled                    | `{}`                       | 
| `global.incomingEmail.user`                  | Incoming email user                    | `""`                       | 
| `global.incomingEmail.password.secret`                  | Secret name with incoming email password                    | See below **(1)**                       | 
| `global.incomingEmail.password.key`                  | Secret key with incoming email password                    | See below **(1)**                       | 
| `global.incomingEmail.expungeDeleted`                  | If incoming email expunge should be deleted                    | `{}`                       | 
| `global.incomingEmail.logger.logPath`                  | Path to logs from incoming email                    | `""`                       | 
| `global.incomingEmail.mailbox`                  | Incoming email mailbox                    | `""`                       | 
| `global.incomingEmail.idleTimeout`                  | Incoming email idleTimeout                    | `""`                       | 
| `global.serviceDeskEmail.enabled`                  | If service desk email should be enabled                    | `{}`                       | 
| `global.serviceDeskEmail.address`                  | Service desk email address                    | `""`                       | 
| `global.serviceDeskEmail.host`                  | Service desk email host                    | `""`                       | 
| `global.serviceDeskEmail.port`                  | Service desk email port                    | `""`                       | 
| `global.serviceDeskEmail.ssl`                  | If service desk email ssl enabled                    | `{}`                       | 
| `global.serviceDeskEmail.startTls`                  | If service desk email startTls enabled                    | `{}`                       | 
| `global.serviceDeskEmail.user`                  | Service desk email user                    | `""`                       | 
| `global.serviceDeskEmail.password.secret`                  | Secret name with service desk email password                    | See below **(1)**                       | 
| `global.serviceDeskEmail.password.key`                  | Secret key with service desk email password                    | See below **(1)**                       | 
| `global.serviceDeskEmail.expungeDeleted`                  | If service desk email expunge should be deleted                    | `{}`                       | 
| `global.serviceDeskEmail.logger.logPath`                  | Path to logs from service desk email                    | `""`                       | 
| `global.serviceDeskEmail.mailbox`                  | Service desk email mailbox                    | `""`                       | 
| `global.serviceDeskEmail.idleTimeout`                  | Service desk email idleTimeout                    | `""`                       | 

Rails & Redis

| Key                                | Description                                                              | Value                        |
|------------------------------------|--------------------------------------------------------------------------|------------------------------|
| `global.rails.minio.provider`                  | Rails Minio provider                    | `""`                       | 
| `global.rails.minio.region`                  | Rails Minio region                    | `""`                       | 
| `global.rails.minio.aws_access_key_id`                  | Rails Minio aws access key id                    | `""`                       | 
| `global.rails.minio.aws_secret_access_key`                  | Rails Minio aws secret access key                    | `""`                       | 
| `global.rails.minio.aws_signature_version`                  | Rails Minio aws signature version                    | `""`                       | 
| `global.rails.minio.host`                  | Rails Minio host                    | `""`                       | 
| `global.rails.minio.endpoint`                  | Rails Minio endpoint                    | `""`                       | 
| `global.rails.minio.path_style`                  | Rails Minio path style                    | `{}`                       | 
| `global.redis.host`                  | Redis host (service)                    | `""`                       | 
| `global.redis.password.enabled`                  | If Redis password is enabled                    | `{}`                       | 
| `global.redis.password.secret`                  | Secret name with Redis password                    | See below **(1)**                       | 
| `global.redis.password.key`                  | Secret key with Redis password                    | See below **(1)**                       | 

General configurations for external dependencies

| Key                                | Description                                                              | Value                        |
|------------------------------------|--------------------------------------------------------------------------|------------------------------|
| `prometheus.install`                  | If Gitlab should install prometheus as dependency                    | `{}`                       |
| `postgresql.install`                  | If Gitlab should install postgresql as dependency                    | `{}`                       |
| `redis.install`                  | If Gitlab should install redis as dependency                    | `{}`                       |
| `nginx-ingress.install`                  | If Gitlab should install nginx-ingress as dependency                    | `{}`                       |
| `certmanager.install`                  | If Gitlab should install certmanager as dependency                    | `{}`                       |
| `certmanager-issuer.email`                  | Certmanager-issuer email                    | `""`                       |
| `registry.storage.secret`                  | Secret name with configurations for bucket registry connection                     | See below **(1)**                       |
| `registry.storage.key`                  | Secret key with configurations for bucket registry connection                     | See below **(1)**                       |
| `registry.minio.s3.v4auth`                  | If bucket connection v4auth is enabled                      | `{}`                       |
| `registry.minio.s3.pathstyle`                  | If bucket connection pathstyle is enabled                      | `{}`                       |
| `registry.minio.s3.regionendpoint`                  | Bucket connection region endpoint                      | `""`                       |
| `registry.minio.s3.region`                  | Bucket connection region                      | `""`                       |
| `registry.minio.s3.bucket`                  | Bucket connection bucket name                      | `""`                       |
| `registry.minio.s3.accesskey`                  | Bucket connection access key                      | `""`                       |
| `registry.minio.s3.secretkey`                  | Bucket connection secret key                      | `""`                       |
| `gitlab.toolbox.backups.objectStorage.config.secret`                  | Secret name with configurations for toolbox backups object storage                     | See below **(1)**                       |
| `gitlab.toolbox.backups.objectStorage.config.key`                  | Secret key with configurations for toolbox backups object storage                     | See below **(1)**                       |

**(1)** In this chart it was opted to have all Gitlab secrets in one single Kubernetes secret.

```yml
psql-password: gitlab-password
email-password: email-password
connection: |
  provider: AWS
  region: eu-central-1
  aws_access_key_id: {{ .Values.dminio.auth.rootUser }} 
  aws_secret_access_key: {{ .Values.dminio.auth.rootPassword }}
  aws_signature_version: 4
  host: minio.example.test
  endpoint: "https://minio.example.test"
  path_style: true
redis-password: redis-password
s3cmd-config: | 
  access_key: {{ .Values.dminio.auth.rootUser }} 
  secret_key: {{ .Values.dminio.auth.rootPassword }}
  bucket_location: eu-central-1
  multipart_chunk_size_mb: 128
minio-credentials: |
  access_key: {{ .Values.dminio.auth.rootUser }} 
  secret_key: {{ .Values.dminio.auth.rootPassword }}
registry-storage : |
  s3:
    v4auth: true
    regionendpoint: "https://minio.example.test"
    pathstyle: true
    region: eu-central-1
    bucket: gitlab-registry-storage
    accesskey: {{ .Values.dminio.auth.rootUser }} 
    secretkey: {{ .Values.dminio.auth.rootPassword }}
ssoProvider: |
  name: "openid_connect"
  label: "Datalab Keycloak"
  args: 
    name: "openid_connect"
    scope: ["openid","profile","email"]
    response_type: "code"
    issuer: "https://keycloak.example.test/auth/realms/datalab-demo"
    discovery: false
    client_auth_method: "query"
    uid_field: "preferred_username"
    client_options:
      identifier: "gitlab-client"
      secret: "7537870f-8e20-4065-a262-5da556549d02"
      redirect_uri: "https://gitlab.example.test/users/auth/openid_connect/callback"
      authorization_endpoint: "https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/auth"
      token_endpoint: "https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/token"
      userinfo_endpoint: "https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/userinfo"
      jwks_uri: "https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/certs"
      end_session_endpoint: "https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/logout"
```

Having all configurations done, the Omniauth option for Single Sing-on with an external authentication provider presented an issue, where the logout action did not logout the user, once it did not delete the cookie session. To fix it, a post-install python script was developped to update the `after_sign_out_path` variable in the admin dashboard. The script simply gets the admin authenticity token and uses it to change the variable value.

```python
#!/usr/bin/python3
"""
Script that creates Personal Access Token for Gitlab API;
Tested with:
- Gitlab Community Edition 10.1.4
- Gitlab Enterprise Edition 12.6.2
- Gitlab Enterprise Edition 13.4.4
"""
import requests
from urllib.parse import urljoin
from bs4 import BeautifulSoup
import datetime
import os

endpoint = "https://gitlab.example.test"
root_route = urljoin(endpoint, "/")
sign_in_route = urljoin(endpoint, "/users/sign_in")
pat_route = urljoin(endpoint, "/-/profile/personal_access_tokens")

login = "root"
password = os.environ["ROOT_PASSWORD"]


def find_csrf_token(text):
    soup = BeautifulSoup(text, "lxml")
    token = soup.find(attrs={"name": "csrf-token"})
    param = soup.find(attrs={"name": "csrf-param"})
    data = {param.get("content"): token.get("content")}
    return data


def obtain_csrf_token():
    r = requests.get(root_route)
    token = find_csrf_token(r.text)
    return token, r.cookies


def sign_in(csrf, cookies):
    data = {
        "user[login]": login,
        "user[password]": password,
        "user[remember_me]": 0,
        "utf8": "✓"
    }
    data.update(csrf)
    r = requests.post(sign_in_route, data=data, cookies=cookies)
    token = find_csrf_token(r.text)
    return token, r.history[0].cookies


def obtain_personal_access_token(name, expires_at, csrf, cookies):
    data = {
        "personal_access_token[expires_at]": expires_at,
        "personal_access_token[name]": name,
        "personal_access_token[scopes][]": "api",
        "utf8": "✓"
    }
    data.update(csrf)
    r = requests.post(pat_route, data=data, cookies=cookies)
    soup = BeautifulSoup(r.text, "lxml")
    token = soup.find('input', id='created-personal-access-token').get('value')
    return token


def main():
    csrf1, cookies1 = obtain_csrf_token()
    print("root", csrf1, cookies1)
    csrf2, cookies2 = sign_in(csrf1, cookies1)
    print("sign_in", csrf2, cookies2)

    name = "token"
    expires_at = (datetime.date.today() + datetime.timedelta(days=1)).strftime("%d-%m-%Y")
    token = obtain_personal_access_token(name, expires_at, csrf2, cookies2)
    print(token)

    r = requests.put("https://gitlab.example.test/api/v4/application/settings?after_sign_out_path=https://keycloak.example.test/auth/realms/datalab-demo/protocol/openid-connect/logout?redirect_uri=https://gitlab.example.test/users/sign_in", headers={'PRIVATE-TOKEN': token})
    print(r.text)

if __name__ == "__main__":
    main()
```
