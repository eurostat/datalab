# Deployment

To deploy the current version of the Data Lab the base requirements are a Kubernetes Cluster with an ingress controller (reverse proxy), and a domain name. However, it is recommended to review all the [Prerequisites](#prerequisites) in order to ensure a proper installation of the datalab Chart. If you have already a running cluster, you can start the deployment from the [Network](#network) section, if you do not, this document also guides the deployment of one in AWS.

The document is divided in the following parts:
1. [Prerequisites](#Prerequisites)  
  1.1. [Kubernetes Cluster](#kubernetes-cluster)  
  1.2. [Network](#network)  
2. [Data Lab Deployment](#data-lab-deployment)  
  2.1. [Helm Chart Deployment](#helm-chart-deployment)  
  2.2. [Manual Steps](#manual-steps)  
  2.3. [Basic Operations](#basic-operations)  
3. [Additional Configurations](#additional-configurations)

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

The whole infrastructure is on top of Kubernetes and installed by Helm, along with the Persistant Volumes for data persistance (e.g., databases), making these hard requirements. The ingress controller and domain name are necessary to expose the datalab to an end user. Note that the ingress controller tested with this installation is the nginx ingress controller, but any ingress controller should work as long as ingress annotations are correct in the `values.yaml`.

The OPTIONAL dependencies are images that have to be created. In order to use CKAN with Keycloak SSO, and possibly customize it, it is necessary to build your own CKAN image. More information on how to do it can be found on the [Chart README](../charts/datalab/README.md). The Keycloak metrics side car is used to expose some Keycloak events as Prometheus metrics, to be then used as a way to measure user inactivity. This side car is optional, but an example for an image can be found under [/images/keycloak-metrics-sidecar/](../images/keycloak-metrics-sidecar/). The user notification container image is also an optional image, that could also be customised for other notification methods, that should expose and endpoint for [Prometheus webhook](https://prometheus.io/docs/alerting/latest/configuration/#webhook_config) in order to route alert triggering notifications for the users themselves (and not only to the platform administrator). An example for the user notification image can be found under [/images/user-notification-container/](../images/user-notification-container/).

<br>
The following sections aim to cover the hard requirements and the installation of the Chart.



### Kubernetes Cluster

This Kubernetes cluster deployment is assuming an AWS environment, if you wish to deploy your Data Lab elsewhere this section is not for you, but it is possible as long as you run it on a Kubernetes cluster (e.g, [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/), [GKE](https://cloud.google.com/kubernetes-engine), on-prem).

To deploy our Kubernetes cluster we use a [Terraform](https://www.terraform.io/) template. This template automatically creates most resources needed to facilitate a clean install of the Data Lab so it can be up and running with ease. Our template creates the following AWS required resources:
 - [VPC (Virtual Private Cloud)](https://aws.amazon.com/vpc/) with the [vpc module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
 - [EKS (Elastic Kubernetes Service)](https://aws.amazon.com/eks/) with the [eks module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest).

We also use an S3 bucket to store the Terraform state, so that developers can individually update the AWS resources without conflicts. Extra support on the remote backend feature for Terraform can be found on the [official Terraform documentation](https://www.terraform.io/docs/language/settings/backends/remote.html).

> You will need to create the S3 bucket backend, or have access to a pre-existing bucket. The key of the Terraform state file can be written with a prefix (e.g., `tfstates/datalab-state-dev`). 

To deploy on AWS ensure you have the authentication taken care of in the [AWS CLI (Command Line Interface)](https://aws.amazon.com/cli/) with the right credentials, you can clone the repository, and inside the `tf/aws_example/` folder create a file called `dev.tfvars` in which you will place the variable configurations as requested in `vars.tf`. For example:
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

To enable the TLS protocol, we will use [Let's Encrypt](https://letsencrypt.org/) as the Certificate Authority, and [certbot](https://certbot.eff.org/) to facilitate the certificates generation. Keeping in mind that the Data Lab requires the certificate to be available in any of the generated sub-domain names, the generation of the certificate must include a wildcard name (example: *.example.test). For example, to only generate the certificate with certbot, you can do:
```
cerbot certonly --manual
```
Ensure you generate a certificate for your sub-domains too, for example: `example.test,*.example.test,*.kub.example.test`.

After following the instructions, set-up your Ingress controller to use your certificates. First, create a secret with the privatekey and the certificate chain:
```
kubectl create secret tls wildcard -n ingress-nginx --key privkey.pem --cert fullchain.pem
```

The Ingress controller will be our point of entrance, it will be done with an [NGINX Ingress controller](https://kubernetes.github.io/ingress-nginx/). We will use AWS Network Load Balancer as the Service Type Load Balancer, but this option is only available on AWS, if you want to reach an cloud agnostic Ingress Controller, you can look into other options such as [traefik](https://traefik.io/).

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

## Data Lab Deployment

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

**IMPORTANT**: create your own `values.yaml` based on the default `values.yaml` with your domain name, SMTP server, and passwords.

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

### Basic Operations

The platform administrator should have access to the admin roles in Kubernetes, Keycloak, and Grafana. With these he can monitor the usage of the platform, manage users and permissions. More information can be found in the [OPERATING.md](./OPERATING.md) documentation.


Onyxia works with the `project` (interchangeable with `group` in the next paragraph) concept, which groups the users into shared services. MinIO and Vault also implement this in their own policies, but to ensure the policies update MinIO uses a cronjob and Vault has to be done manually as described in the previous section. This concept is implemented through the `groups` claim in the `jwt` token, which is in fact managed by Keycloak (or an external identity provider). The platform administrator with access to the identity provider is the one responsible for this group assigning, and triggering the policy change in Vault.


Quotas and thresholds for alerts can be setup in the `values.yaml`, however, it is also possible to configure them during runtime, by changing the ConfigMap `prometheus-alerts`, which in turn will be reloaded by the Prometheus server sidecar for ConfigMap reload. Note that the receiver should be the platform administrator that can then act upon the alert triggering, either by communicating with the users or by taking action in the cluster (e.g., helm uninstall of a long running inactive service).

## Additional Configurations

It is possible to do further configurations around the deployed Data Lab, namely add more Prometheus rules or Grafana dashboards. Complementary information is given on [OPERATING.md](./OPERATING.md).

In the future, any additional configurations will be specified here. Work in progress... :hammer_and_wrench: :warning:
