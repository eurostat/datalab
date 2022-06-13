# Deployment

To deploy the current version of the Data Lab the base requirements are a Kubernetes Cluster with an ingress controller (reverse proxy), and a domain name. However, it is recommended to review all the [Prerequisites](#prerequisites) in order to ensure a proper installation of the datalab Chart. This document covers two ways to launch the datalab, manually, where you must follow the instructions from two sections, [Infrastructure Deployment - Manual](#infrastructure-deployment-manual) and [Data Lab Deployment - Manual](#data-lab-deployment),  or automatically, where you will follow the instructions from [Automatic Deployment](#automatic-deployment). If you have already a running cluster, you will follow the manual deployment and you can start the deployment from the [Network](#network) section.

The document is divided in the following parts:
1. [Prerequisites](#Prerequisites)<br>
2. [Infrastructure Deployment - Manual](#infrastructure-deployment-manual)<br>
  2.1. [Kubernetes Cluster](#kubernetes-cluster)  
  2.2. [Network](#network)  
3. [Data Lab Deployment - Manual](#data-lab-deployment)<br>
  3.1. [Helm Chart Deployment](#helm-chart-deployment)  
  3.2. [Manual Steps](#manual-steps)  
4. [Automatic Deployment](#automatic-deployment)
5. [Basic Operations](#basic-operations)  
6. [Additional Configurations](#additional-configurations)
7. [Destroy Deployment](#destroy-deployment)

## Prerequisites

There are a few prerequisites to install the [datalab Helm Chart](../charts/datalab/README.md):
- Kubernetes 1.20+
- Helm 3
- PV provisioner support in the underlying infrastructure
- Ingress controller (e.g., nginx ingress controller)
- Domain name and records pointing to the ingress controller
- (RECOMMENDED) wildcard TLS certificate configured for the ingress controller
- (RECOMMENDED) SMTP server for automated messages and authentication methods configuration in Keycloak
- (OPTIONAL) Ckan image with SSO configuration (Ckan extension + Keycloak Client definition)
- (OPTIONAL) Keycloak metrics side car image (to measure user activity based on Keycloak events)
- (OPTIONAL) User notification container image (to notify users of their own alerts)

The whole infrastructure is on top of Kubernetes and installed by Helm, along with the Persistant Volumes for data persistance (e.g., databases), making these hard requirements. The ingress controller and domain name are necessary to expose the datalab to an end user. Note that the ingress controller tested with this installation is the nginx ingress controller, but any ingress controller should work as long as ingress annotations are correct in the `values.yaml` file inside the Data Lab chart.

The OPTIONAL dependencies are images that have to be created. In order to use CKAN with Keycloak SSO, and possibly customize it, it is necessary to build your own CKAN image. More information on how to do it can be found on the [Chart README](../charts/datalab/README.md). The Keycloak metrics side car is used to expose some Keycloak events as Prometheus metrics, to be then used as a way to measure user inactivity. This side car is optional, but an example for an image can be found under [/images/keycloak-metrics-sidecar/](../images/keycloak-metrics-sidecar/). The user notification container image is also an optional image, that could also be customised for other notification methods, that should expose and endpoint for [Prometheus webhook](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config) in order to route alert triggering notifications for the users themselves (and not only to the platform administrator). An example for the user notification image can be found under [/images/user-notification-container/](../images/user-notification-container/).

In order to install the Data Lab chart it is necessary to create your own `values.yaml` based on the default `values.yaml`, that is inside the Data Lab chart,  with your domain name, SMTP server, and passwords. You just need to search in the file for `(TODO)` and make your own configurations.

First you need to set your domain name. Make sure you change all occurrences of `example.test` in the file. You can see two examples below, we emphasize that this substitution has to be done in more places:

```yaml
domainName: "example.test"
...
rules:
  - host: "keycloak.example.test"
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
    "fromDisplayName": "datalab.example.test",
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
        smtp_from: example.test@example.test
        smtp_smarthost: smtp.example.test:587
        smtp_auth_username: example.test@example.test
        smtp_auth_password: example-password
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
            - to: example@example.test
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
Finally, you need to set the Superset node configuration and usernames and passwords for database connection:
```yaml
...
supersetNode:
  command:
    - "/bin/sh"
    - "-c"
    - ". {{ .Values.configMountPath }}/superset_bootstrap.sh; /usr/bin/run-server.sh"
  connections:
    redis_host: datalab-dredis-headless
    redis_password: redis-password
    redis_port: "6379"
    db_host: postgres-headless
    db_port: "5432"
    db_user: superset
    db_pass: superset
    db_name: superset
...
```
In order to perform the commands in the future sections, [AWS CLI](https://aws.amazon.com/cli/) (for AWS deployments, [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli) and [Helm CLI](https://helm.sh/docs/intro/install/) are needed.
<br>
The following sections aim to cover the hard requirements and the installation of the Chart.
<br>
<br>

## Infrastructure Deployment - Manual 

This installation method will allow you to have more control of all the steps necessary to install the Data Lab chart, allowing a more phased installation and even the use of a previously created Kubernetes cluster. If you want an easier installation with less settings, follow the [Automatic Deployment](#automatic-deployment) steps.

### Kubernetes Cluster

This Kubernetes cluster deployment is assuming an AWS environment, if you wish to deploy your Data Lab elsewhere this section is not for you, but it is possible as long as you run it on a Kubernetes cluster (e.g, [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/), [GKE](https://cloud.google.com/kubernetes-engine), on-prem).

To deploy our Kubernetes cluster we use a [Terraform](https://www.terraform.io/) template. This template automatically creates most resources needed to facilitate a clean install of the Data Lab so it can be up and running with ease. Our template creates the following AWS required resources:
 - [VPC (Virtual Private Cloud)](https://aws.amazon.com/vpc/) with the [vpc module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
 - [EKS (Elastic Kubernetes Service)](https://aws.amazon.com/eks/) with the [eks module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest).

We also use an S3 bucket to store the Terraform state, so that developers can individually update the AWS resources without conflicts. Extra support on the remote backend feature for Terraform can be found on the [official Terraform documentation](https://www.terraform.io/docs/language/settings/backends/remote.html).

> You will need to create the S3 bucket backend, or have access to a pre-existing bucket. The key of the Terraform state file can be written with a prefix (e.g., `tfstates/datalab-state-dev`). 

To deploy on AWS ensure you have the authentication taken care of in the [AWS CLI (Command Line Interface)](https://aws.amazon.com/cli/) with the right credentials, you can clone the repository, and inside the `tf/aws_example_manual/` folder create a file called `dev.tfvars` in which you will place the variable configurations as requested in `vars.tf`. For example:
```
CLUSTER_PREFIX = "estat"
MAP_USERS = [{
userarn = "arn:aws:iam::***:user/exampleuser"
username = "exampleuser"
groups = ["system:masters"]
}]
MAP_ROLES = []
ALLOWED_IPS = [ "203.0.113.0/32" ]
```

For development, we choose to have our cluster private, so only developers with their IP on the whitelist can access the cluster, so in the previous example only the IP `203.0.113.0` would have access to the Kubernetes API. Note that EKS also requires mapping of IAM users that did not create the cluster to be granted access.

To do the actual deployment, you can initiate the backend configuration and apply it with the newly created `dev.tfvars`:

```
terraform init -backend-config="bucket=************" -backend-config="key=************" -backend-config="region=eu-central-1"

terraform apply -var-file="dev.tfvars"
```

After deployment, to configure your developer [kubectl](https://kubernetes.io/docs/tasks/tools/), use the AWS CLI to run the command to update your kubeconfig as described on [AWS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html):
```
aws eks --region eu-central-1 update-kubeconfig --name <cluster_name>
```

> There are numerous advantages by having the EKS cluster being created and deleted continuously during the development stage on-off hours (off work schedule), the most important being the reduction of costs. To achieve this workflow, you can take a look at the automatic procedure to start the EKS cluster by 8h00 (GMT) and delete it by 19h00 (GMT) from Monday to Friday in [`.github/example_workflows`](../.github/example_workflows).

### Network

After having the Kubernetes Cluster up and running, the only steps missing are to set-up the TLS protocol, the Ingress controller and the DNS records. For that purpose, it is necessary to own a domain name.

To enable the TLS protocol, we will use [Let's Encrypt](https://letsencrypt.org/) as the Certificate Authority, and [certbot](https://certbot.eff.org/) to facilitate the certificates generation. This decision was made, taken into consideration cloud agnostic environment, but other Certificate Authorities can be used. For instance, one could use [AWS ACM](https://aws.amazon.com/certificate-manager/), and later the generated certificate could be referred to in the ingress controller. If the `nginx-ingress-controller` is being used, this reference could be created using the `nginx-ingress-controller` service annotations:

```yaml
annotations:
  io/aws-load-balancer-ssl-cert: {aws_acm_certificate.arn}
```

The same goes for any other cloud provider with equivalent services. While the next instructions used certbot, the creation of certificates in other Certificate Authorities follow similar steps.

Keeping in mind that the Data Lab requires the certificate to be available in any of the generated sub-domain names, the generation of the certificate must include a wildcard name (example: *.example.test). For example, to only generate the certificate with certbot, you can do:
```
certbot certonly --manual
```
Ensure you generate a certificate for your sub-domains too, for example: `example.test,*.example.test,*.kub.example.test`.

After following the instructions, set-up your Ingress controller to use your certificates. First, create a secret with the privatekey and the certificate chain:
```
kubectl create secret tls wildcard -n ingress-nginx --key privkey.pem --cert fullchain.pem
```

The Ingress controller will be our point of entrance, it will be done with an [NGINX Ingress controller](https://kubernetes.github.io/ingress-nginx/). We will use AWS Network Load Balancer as the Service Type Load Balancer, but this option is only available on AWS, if you want to reach an cloud agnostic Ingress Controller, you can look into other options such as [traefik](https://traefik.io/) to achieve full cloud agnosticity. However, there is also the option of using NGINX Ingress controller for other cloud provider, as can be consulted [here](https://kubernetes.github.io/ingress-nginx/deploy/).

The simplest way to deploy it is to use the manifest provided by [Kubernetes Community](https://kubernetes.github.io/ingress-nginx/deploy/#aws), or similar manifests that you manage on your side.
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.4/deploy/static/provider/aws/deploy.yaml
```

If you want to filter IPs that have access to your development cluster, you can set `spec.loadBalancerSourceRanges` on the `Service` of type `LoadBalancer`. Then add the flag `--default-ssl-certificate=ingress-nginx/wildcard` to your controller arguments to ensure your ingress controller has access to the certificates. Using the Kubernetes Community manifests the added lines will look like this:
```yaml
...
apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
annotations: {}
...
spec:
    type: LoadBalancer
    ...
    loadBalancerSourceRanges: # NEW-LINES (1)
    - "203.0.113.0/32"        # NEW-LINES (2) ip to open
    - "203.0.113.1/32"        # NEW-LINES (3) ip to open
...
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
...
spec:
...
    template:
        spec:
            - name: controller
            ...
            args:
                - /nginx-ingress-controller
                - ...
                - --default-ssl-certificate=ingress-nginx/wildcard # NEW-LINE to use secret
...
```

Finally, the domain must redirect to the ingress controller. Create a wildcard record for your previously created Service that exposes the ingress controller, for example, to expose the `NLB` create a `CNAME` record for `*.example.test` to `xxx.elb.<region>.amazonaws.com`.

## Data Lab Deployment - Manual

Before the actual deployment, and with the [Prerequisites](#prerequisites) covered, take into account the following points:
- Services are generated randomly under a sub-domain `*.your-domain-name.test`, so your TLS certificate should have a wildcard
- Keycloak realm is `datalab-demo`, so all references for SSO should point to this realm 
- Keycloak clients for Apache Superset, Grafana, MinIO and Ckan are also constant: `apache-superset`, `grafana`, `minio` and  `ckan`
- Disable the optional features that you do not have an image for
- Choose how your PostgreSQL deployment will be (one per service in sub-dependency or a common database)

### Helm Chart Deployment

The Helm Chart deployment itself, can be done from the Helm repo (https://eurostat.github.io/datalab/) or locally from a clone (https://github.com/eurostat/datalab). It is advised to pass through the [Chart README](../charts/datalab/README.md) before deploying.

```
helm repo add eurostat-datalab https://eurostat.github.io/datalab/
helm repo update
helm show values eurostat-datalab/datalab > values.yaml
```

**IMPORTANT**: create your own `values.yaml` based on the default `values.yaml` with your domain name, SMTP server, and passwords, as explained in the [Prerequisites Section](#prerequisites).

> **ATTENTION** ensure you do not commit your `values.yaml` with secrets to the SCM.

```
helm upgrade --install datalab eurostat-datalab/datalab -f values.yaml --wait
```

### Manual Steps

Some manual steps are necessary to fully complete the datalab deployment:
- Vault initialisation and unsealing
- Vault JWT authentication setup
- Vault group policy synchronization
- (OPTIONAL) MinIO group policy synchronization
- (OPTIONAL) Extend alert rules

After Keycloak's pod is ready, initialise and [unseal HashiCorp's Vault](https://www.vaultproject.io/docs/concepts/seal) and configure it to be used by Onyxia and Keycloak `jwt` authentication, more on this can be read in the official documentation [Hashicorp's Vault JWT Auth](https://www.vaultproject.io/docs/auth/jwt).

```bash
kubectl exec --stdin --tty datalab-vault-0 -- /bin/sh

# inside the pod
vault operator init -key-shares=5 -key-threshold=3

# ******************** IMPORTANT ******************** 
# Get Unseal Key shares and root token: keep them SAFE!
# ******************** IMPORTANT ********************

vault operator unseal # key share 1
vault operator unseal # key share 2
vault operator unseal # key share 3

# Run the mounted configmap with the root-token as env var
VAULT_TOKEN=<root-token> ./vault/scripts/configscript.sh

# you can exit the pod - remember to keep the unseal key shares and initial root token
exit
```

Enable CORS for Onyxia access to Vault, and run the [helper script](../charts/datalab/helpers/vault-groups-config.sh) (or equivalent) with your own desired groups (projects).
```bash
# fill in the received root token and your own vault ingress addr
export VAULT_TOKEN=<root-token>
export VAULT_ADDR=https://vault.example.test
# ensure to change the domain name of your Onyxia ingress addr
curl --header "X-Vault-Token: $VAULT_TOKEN" --request PUT --data '{"allowed_origins": ["https://datalab.example.test", '"\"$VAULT_ADDR\""' ]}'  $VAULT_ADDR/v1/sys/config/cors
# ensure to change the GROUP_LIST variable for your desired groups and run it
sh /<path/to/your/helper/script>/vault-groups-config.sh
```

MinIO should have it's pre-configured policy for each user based on the [policy-template.tpl](../charts/datalab/templates/_policy-template.tpl), and there is a cronjob that will ensure a synchronization with group membership in Keycloak and policies in MinIO. However, if you want to ensure that synchronization is executed, you can always create a job out of the cronjob specification:
```bash
kubectl create job --from=cronjob/policy-update-cronjob immediate-policy-update
```

If alert rules changes are required you can edit the configmap `prometheus-alerts` after or [before](../charts/datalab/templates/prometheus-rules-cm.yaml) deployment. This will trigger a reload of the configmap and the creation of the alert rules in the Prometheus server. For more information on how to write the rules, visit the official [Prometheus documentation](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/). 

## Automatic Deployment

To facilitate most of the configurations described in the previous sections, there was also a Terraform template which was developed in order to accelerate the environment set-up. This template was design to lauch the Data Lab using AWS resources, however, switching to another Cloud Provider should be relatively easy. For the installation to be easier it is recommended that you clone the [repository](https://github.com/eurostat/datalab) in order to have everything available locally. The template can be found within the source code of this project under the `tf/aws_example_auto` folder. 

Before installation, it is necessary to ensure that you have acquired a domain name (does not have to be from AWS), and a hosted zone, on [AWS Route53](https://aws.amazon.com/pt/route53/), for the respective domain name. 

To deploy on AWS ensure you have the authentication taken care of in the [AWS CLI (Command Line Interface)](https://aws.amazon.com/cli/) with the right credentials, and inside the `tf/aws_example_auto/` folder create a file called `dev.tfvars` in which you will place the variable configurations as requested in `vars.tf`. For example:
```
AWS_REGION = "eu-central-1"
CLUSTER_PREFIX = "estat"
ENVIRONMENT = "dev"
MAP_USERS = [{
userarn = "arn:aws:iam::***:user/exampleuser"
username = "exampleuser"
groups = ["system:masters"]
}]
MAP_ROLES = []
ALLOWED_IPS = [ "203.0.113.0/32" ]
EXTRA_ALLOWED_IPS = []
DOMAIN_NAME = "dev.example.com"
DOMAIN_NAME_HOSTED_ZONE = "example.com"
EMAIL = "example@email.com"
INGRESS_ALLOWED_IPS = ["203.0.113.0/32"]
PATH_TO_NGINX_CONTROLLER_CHART = "../../charts/ingress-nginx"
PATH_TO_NGINX_CONTROLLER_VALUES = "../../charts/ingress-nginx/values.yaml"
PATH_TO_DATALAB_CHART = "../../charts/datalab"
PATH_TO_DATALAB_VALUES = "../../charts/datalab/values.yaml"
PATH_TO_CERTIFICATE_CRT = "./fullchain.pem"
PATH_TO_CERTIFICATE_KEY = "./privkey.pem"
```
As you can see above, the last 6 variables allow us to indicate the location of the Helm charts we need for the installation, nginx-controller chart and the Data Lab chart, the respective paths to the configuration files, and the paths to the certificate and certificate key. The default values ​​for the Data Lab and nginx-controller variables are set to the paths where these charts and configurations are found if you clone the [Data Lab repository](https://github.com/eurostat/datalab). 


To add the certificate to our implementation we have two options:
  - In the first one, we create the certificate in advance, following the instructions in the [Network Setion](#network), and then we change the variables `PATH_TO_CERTIFICATE_CRT` and `PATH_TO_CERTIFICATE_KEY` to the directory where the certificate files are stored. 
  - In the second, a TLS Certificate, available for all the sub-domains required by the Data Lab, is created during the execution of the terraform template. This option uses [Let's Encrypt](https://letsencrypt.org/) as the Certificate Authority, and [ACME](https://registry.terraform.io/providers/vancluever/acme/latest/docs) to automate the certificates generation. To use this option, you must not define the two variables, `PATH_TO_CERTIFICATE_CRT` and `PATH_TO_CERTIFICATE_KEY`, so that they have their default values, that is, equal to `""`.

For the certificate variables, you must first create the certificate, following the instructions in the [Network Setion](#network), and then change the variables `PATH_TO_CERTIFICATE_CRT` and `PATH_TO_CERTIFICATE_KEY` to the directory where the certificate files are stored. There is an option where the terraform template can generate a TLS Certificate, available for all the sub-domains required by the Data Lab. This option uses [Let's Encrypt](https://letsencrypt.org/) as the Certificate Authority, and [ACME](https://registry.terraform.io/providers/vancluever/acme/latest/docs) to automate the certificates generation. To use this option, you must not define the two variables, `PATH_TO_CERTIFICATE_CRT` and `PATH_TO_CERTIFICATE_KEY`, so that they have their default values, that is, equal to "".

This template automatically installs the Data Lab, performing the following steps:

 - Creates a [VPC (Virtual Private Cloud)](https://aws.amazon.com/vpc/) with the [vpc module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
 - Creates a [EKS (Elastic Kubernetes Service)](https://aws.amazon.com/eks/) with the [eks module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest).
 - Manages a Route53 Hosted Zone - prior creation of a hosted zone on aws Route53 is required.
 - Creates a Kubernetes Secret, using the [kubernetes_secret resource](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret), with the private key and the certificate chain of the certificate we indicate in the `dev.tfvars` file.
- Installs the [nginx-controller](https://kubernetes.github.io/ingress-nginx/) Helm Chart. The repository must be local. Uses a `values.yaml` file to configure all necessary settings, such as indicating the use of AWS Network Load Balancer (NLB) as the Service Type Load Balancer and pointing the `default-ssl-certificate` option to the secret created.
- Automatically creates a wildcard CNAME record in the hosted zone that points to the NLB, using the [AWS Route53 Record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record). The name will be of the following format: `*.DOMAIN_NAME`.
- Finally, installs the Data Lab Helm Chart, locally from a clone (https://github.com/eurostat/datalab). Uses a `values.yaml` file to set all the necessary settings. You need to create your own `values.yaml` based on the default `values.yaml` with your domain name, SMTP server, and passwords, as explained in the [Prerequisites Section](#prerequisites). Then, change `PATH_TO_DATALAB_VALUES` variable to point to that file. If you wish to use several domain names leave the domain name equals to `example.test`. The domain name will then be automatically updated, at the beginning of the terraform template, with the values established at the `dev.tfvars` file, using the `DOMAIN_NAME` variable. ***DISCLAIMER*** - the email used in the smtp server must not contain the expression `example.test`, so the following email would not work - `example.test@mail.com`.

Of the resources mentioned above the following are not cloud agnostic:

1. [AWS EKS](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
2. [AWS VPC](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
3. [AWS Route53 Record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)
4. [NGINX Ingress controller](https://kubernetes.github.io/ingress-nginx/)

As it should be noticeable, these resources could be adapted to any other cloud provider. AWS EKS have similar services in most cloud providers, and Terraform has resources for the majority of them, as can be consulted [here](https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider).

For the VPC, the situation is similar to EKS, but cloud providers have a more specific configuration for network, which means this resource should be configured as such.

In the context of DNS Providers, if they are hosted in a cloud provider, then Terraform will have resources to dynamically change them, such as [azurerm_dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone) for Azure. But if the domain is hosted in an external DNS Provider to the cloud, than this step can be hard to automate, however, there is still the option of taking this resource out of the template and process this step manually.

Finally, the NGINX Ingress controller could be substituted by any cloud Load Balancer, be used according to the [Kubernetes environment](https://kubernetes.github.io/ingress-nginx/deploy/), or even be replaced by [traefik](https://traefik.io/), as was stated above. If it is decided to use a version of NGINX Ingress controller according to the cloud provider, the simple replacement of the helm chart under the folder `charts` could be made to accomplish the objective.

Finally, after having all the configurations completed, and [Terraform Plan](https://www.terraform.io/cli/commands/plan) reviewed, this deployment follows the same steps as above, which means a bucket or file structure to save the [Terraform State](https://www.terraform.io/language/state) should already be in place, so that the following commands run successfully:

```
terraform init -backend-config="bucket=************" -backend-config="key=************" -backend-config="region=************"

terraform apply -var-file="dev.tfvars"
```

After deployment, to configure your developer [kubectl](https://kubernetes.io/docs/tasks/tools/), use the AWS CLI to run the command to update your kubeconfig as described on [AWS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html):
```
aws eks --region eu-central-1 update-kubeconfig --name <cluster_name>
```

> There are numerous advantages by having the EKS cluster being created and deleted continuously during the development stage on-off hours (off work schedule), the most important being the reduction of costs. To achieve this workflow, you can take a look at the automatic procedure to start the EKS cluster by 8h00 (GMT) and delete it by 19h00 (GMT) from Monday to Friday in [`.github/example_workflows`](../.github/example_workflows).

After all the resources have been created successfully, the only remaining processes are the [Manual Steps](#manual-steps) referred in the above section. 

## Basic Operations

The platform administrator should have access to the admin roles in Kubernetes, Keycloak, and Grafana. With these he can monitor the usage of the platform, manage users and permissions. More information can be found in the [OPERATING.md](./OPERATING.md) documentation.


Onyxia works with the `project` (interchangeable with `group` in the next paragraph) concept, which groups the users into shared services. MinIO and Vault also implement this in their own policies, but to ensure the policies update MinIO uses a cronjob and Vault has to be done manually as described in the [Manual Steps](#manual-steps) section. This concept is implemented through the `groups` claim in the `jwt` token, which is in fact managed by Keycloak (or an external identity provider). The platform administrator with access to the identity provider is the one responsible for this group assigning, and triggering the policy change in Vault.


Quotas and thresholds for alerts can be setup in the `values.yaml`, however, it is also possible to configure them during runtime, by changing the ConfigMap `prometheus-alerts`, which in turn will be reloaded by the Prometheus server sidecar for ConfigMap reload. Note that the receiver should be the platform administrator that can then act upon the alert triggering, either by communicating with the users or by taking action in the cluster (e.g., helm uninstall of a long running inactive service).

## Additional Configurations

It is possible to do further configurations around the deployed Data Lab, namely add more Prometheus rules or Grafana dashboards. Complementary information is given on [OPERATING.md](./OPERATING.md).

In the future, any additional configurations will be specified here. Work in progress... :hammer_and_wrench: :warning:

## Destroy Deployment

For taking down the Datalab and/or the whole infrastructure, one should follow the following steps.

If the deployment was made through the manual steps, the releases of the Data Lab and Ingress-nginx should be deleted first.

Through `helm ls -A`, a user should be able to list all installed charts. After that, with `helm delete <release-name>` and `helm delete <release-name> -n <namespace>` both releases should be deleted.

If the deployment was made throught the automatic steps, only the Data Lab release must be destroyed.

Apart from which kind of deployment was used, at this stage, running the following command `kubectl delete pvc --all -A ` is advised, once most PVCs (Persistent Volume Claims) are not attatched to the respective helm releases, and will not be automatically deleted after the `helm delete` command.

After these preparations steps, inside the terraform template used, the following commands must be ran:

```bash
terraform state rm module.eks.kubernetes_config_map.aws_auth
terraform destroy -var-file="dev.tfvars" -auto-approve
```

This will delete all other resources previously launched and clean the environment.
