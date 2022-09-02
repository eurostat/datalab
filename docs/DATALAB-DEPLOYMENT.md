# Data Lab installation 

Once you have the infrastructure and the environment, you are ready to deploy the Data lab following the steps described here below. It is recommended to review all the [Prerequisites](#prerequisites) in order to ensure a proper installation.

### Prerequisites

- [Kubernetes CLI 1.20+](https://kubernetes.io/releases)
- PV provisioner support in the underlying infrastructure
- Kubernetes cluster
- Ingress controller (e.g., nginx ingress controller)
- Domain name and records pointing to the ingress controller
- (RECOMMENDED) wildcard TLS certificate configured for the ingress controller
- (RECOMMENDED) SMTP server for automated messages and authentication methods configuration in Keycloak
- (OPTIONAL) Ckan image with SSO configuration (Ckan extension + Keycloak Client definition)
- (OPTIONAL) Keycloak metrics side car image (to measure user activity based on Keycloak events)
- (OPTIONAL) User notification container image (to notify users of their own alerts)

The whole infrastructure is on top of Kubernetes and installed by Helm, along with the Persistant Volumes for data persistance (e.g., databases), making these hard requirements. The ingress controller and domain name are necessary to expose the datalab to an end user. Note that the ingress controller tested with this installation is the nginx ingress controller, but any ingress controller should work as long as ingress annotations are correct in the `values.yaml` file inside the Data Lab chart.

The OPTIONAL dependencies are images that have to be created. In order to use CKAN with Keycloak SSO, and possibly customise it, it is necessary to build your own CKAN image. More information on how to do it can be found on the [Chart README](../charts/datalab/README.md). The Keycloak metrics side car is used to expose some Keycloak events as Prometheus metrics, to be then used as a way to measure user inactivity. This side car is optional, but an example for an image can be found under [/images/keycloak-metrics-sidecar/](../images/keycloak-metrics-sidecar/). The user notification container image is also an optional image, that could also be customised for other notification methods, that should expose and endpoint for [Prometheus webhook](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config) in order to route alert triggering notifications for the users themselves (and not only to the platform administrator). An example for the user notification image can be found under [/images/user-notification-container/](../images/user-notification-container/).

The following steps aim to cover the installation of the data lab Chart and its initialization steps.

Before the actual deployment, and with the [Prerequisites](#prerequisites) covered, please take into account the following points:
- Services are generated randomly under a sub-domain `*.your-domain-name.test`, so your TLS certificate should have a wildcard
- Keycloak realm is `datalab-demo`, so all references for SSO should point to this realm 
- Keycloak clients for Apache Superset, Grafana, MinIO and Ckan are also constant: `apache-superset`, `grafana`, `minio` and  `ckan`
- Disable the optional features that you do not have an image for
- Choose how your PostgreSQL deployment will be (one per service in sub-dependency or a common database)

In order to install the Data Lab chart it is necessary to create your own `values.yaml` based on the default `values.yaml`, that is inside the Data Lab chart,  with your domain name, SMTP server, and passwords. You just need to search in the file for `(TODO)` and make your own configurations.

First you need to set your domain name. Make sure you change all occurrences of `your-domain-name.test` in the file. You can see two examples below, we emphasize that this substitution has to be done in more places:

```yaml
domainName: "your-domain-name.test"
...
rules:
  - host: "keycloak.your-domain-name.test"
...
```
Then you need to set up the smpt server. For this, you need an email that you want to use for this purpose. Each email provider will have a different way of configuring the smtp server. So you have to check how to do it for your provider. For the gmail provider you can check the following example:
```yaml
...
smtpServer: |-
  {
    "password": "password",
    "starttls": "true",
    "auth": "true",
    "port": "587",
    "host": "smtp.gmail.com",
    "from": "example@mail.com",
    "fromDisplayName": "datalab.your-domain-name.test",
    "ssl": "",
    "user": "example@mail.com"
  }
...
```
You can configure the PostgreSQL secrets for keycloak to use, set the Keycloak admin user and password, set MinIO root credentials, and set the admin credentials for Grafana:
```yaml
...
 # (TODO) Set PostgreSQL secrets for Keycloak to use
postgresql:
  enabled: false
  postgresqlUsername: keycloak
  postgresqlPassword: keycloak
  postgresqlDatabase: keycloak
...
```
```yaml
...
# (TODO) Set Keycloak admin user and password
kcUser: admin
kcPassword: admin
...
```
```yaml
...
 # (TODO) Set MinIO root credentials (password has to be bigger than 8 characters)
auth:
  rootUser: &minioRootUser "minio-admin"
  rootPassword: &minioRootPassword "minio-secret-password"
...
```
```yaml
...
grafana:
  enabled: true
  # (TODO) Place your own admin credentials here
  adminUser: admin
  adminPassword: strongpassword
...
```

You also need to define your own alertmanager.yml configuration:
```yaml
...
alertmanagerFiles:
    alertmanager.yml:
      global:
        resolve_timeout: 5m
        http_config:
          follow_redirects: true
        smtp_from: your-domain-name.test@your-domain-name.test
        smtp_smarthost: smtp.your-domain-name.test:587
        smtp_auth_username: your-domain-name.test@your-domain-name.test
        smtp_auth_password: your-domain-name.test
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
            - to: example@your-domain-name.test
      templates: []
...
```
If you want to use Keycloak SSO, after you create your own CKAN image, you need to set the client secret and the image in this configuration file:
```yaml
...
ckan:
  clientsecret: your-client-secret

  image:
    repository: # (TODO) place your own image here! 
    tag: ckan2.9v2-acl
    pullPolicy: Always
...
```
If you want to measure user activity based on Keycloak events, after you create your own Keycloak Sidecar metrics image, you need to uncomment the section below and replace the placeholders.
```yaml
...
  extraContainers: |
    - name: keycloak-event-metrics-sidecar
      image: #TODO #placeholder
      imagePullPolicy: IfNotPresent
      env:
        - name: KEYCLOAK_SC__SVC_NAME
          value: http://localhost:8080
        - name: KEYCLOAK_ADMIN_USERNAME
          value: admin
        - name: KEYCLOAK_ADMIN_PASSWORD
          value: admin
      ports:
        - containerPort: 9991
          name: event-sidecar
          protocol: TCP
...
```
Finally, you need to set the Superset node configuration and usernames and passwords for database connection:
```yaml
...
supersetNode:
  command:
    - "/bin/sh"
    - "-c"
    - ". {{ .Values.configMountPath }}/superset_bootstrap.sh; /usr/bin/run-server.sh"
  connections:
    redis_host: dredis-headless
    redis_password: redis-password
    redis_port: "6379"
    db_host: postgres-headless
    db_port: "5432"
    db_user: superset
    db_pass: superset
    db_name: superset
...
```

### Helm Chart Deployment

The Helm Chart deployment itself, can be done from the Helm repo (https://eurostat.github.io/datalab/) or locally from a clone (https://github.com/eurostat/datalab). It is advised to pass through the [Chart README](../charts/datalab/README.md) before deploying.

**IMPORTANT**: create your own `values.yaml` based on the default `values.yaml` with your domain name, SMTP server, and passwords, as explained in the [Prerequisites Section](#prerequisites), following the instructions from the previous section.

> **ATTENTION** ensure you do not commit your `values.yaml` with secrets to the SCM.

Using the prompt, go to the folder where the datalab charts are located (inside the `datalab` repository main folder, in `charts`, then `datalab`).
 Type the command below and execute it on prompt.

```
helm upgrade --install datalab . -f .\values.yaml 
```

If you wish to change the release name to other than `datalab`, please change the host in the redis of gitlab in the `values.yaml` file.

```yaml
...
    redis:
      host: datalab-dredis-headless
      password:
        enabled: true
        secret: gitlab-secrets
        key: redis-password
...
```

## Initialize Vault

After successful installation, configure HashiCorp's Vault to be used by Onyxia and Keycloak `jwt` authentication. 
```bash
kubectl exec --stdin --tty datalab-vault-0 -- /bin/sh

# inside the pod... place both to 1 in development for ease of use
vault operator init -key-shares=1 -key-threshold=1

# ******************** IMPORTANT ******************** 
# Get Unseal Key shares and root token: keep them SAFE!
# ******************** IMPORTANT ********************

vault operator unseal # key share 1


# Run the mounted configmap with the root-token as env var
VAULT_TOKEN=<root-token> ./vault/scripts/configscript.sh
```

And enable CORS for Onyxia access.
```
curl --header "X-Vault-Token: <root-token>" --request PUT --data '{"allowed_origins": ["https://datalab.your-domain-name.test", "https://vault.your-domain-name.test" ]}'  https://vault.your-domain-name.test/v1/sys/config/cors
```

## Restart MinIO

MinIO has some trouble configuring all authentication and policies services, so most times the deployment responsible form MinIO should be restarted in order to re-establish all configurations necessary.

```bash
kubectl rollout restart deploy datalab-dminio
```

## Set roles permissions on Superset

The roles in Apache Superset are set correctly, but to get the desired outcome out of them, we must rectify the priviledges in each of them. After logging in with the default admin, change the roles with the following rules: 

- Alpha role: add `can write on Database` & `menu access SQL Lab` & `can sql json on Superset` permission
- Gamma role: add `all database access on all_database_access` & `all datasource access on all_datasource_access` & `all query access on all_query_access` & `menu access SQL Lab` & `can sql json on Superset` permission.
