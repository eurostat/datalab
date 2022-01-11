# Deployment

To deploy the current version of the Data Lab the only requirements are a Kubernetes Cluster with an ingress controller (reverse proxy), and a domain name. If you have one, you can start the deployment from [here](#network). However, if you do not have a Kubernetes Cluster, this document guides you to the deployment of one in AWS.

The document is divided in four parts:
1. [Kubernetes Cluster](#kubernetes-cluster)
2. [Network](#network)
3. [Data Lab Deployment](#data-lab-deployment)
4. [Additional Configurations](#additional-configurations)

## Kubernetes Cluster

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

## Network

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

There are a few steps required to launch a complete instance of our Helm Chart:
1. Getting a domain and updating its DNS values, as well as configuring TLS certificates
2. Get an SMTP Server (email) to enable Keycloak to have all its features available
3. Match a `_realm-template.tpl` definition of `Realm` and `Clients` with your set values
4. Create a `onyxia-web` image to add necessary connections (p.e. to the data catalog)
5. Create a `Ckan` image to enable Keycloak's SSO on image build
6. Decide wether to create multiple databases or just one and set `values.yaml` accordingly

Helm install complete package with all the initial configurations already set up, for more information on the Chart check the [Chart README.md](../charts/datalab/README.md). *Helm Charts must be adapted to the domain used*

Keep in mind it is necessary to:
- have the created Ckan image published and referenced in `values.yaml` if the data catalog feature is desired.
  - have the created Onyxia-web image published and referenced in `values.yaml` if it is desired to have a  link in the frontend redirecting to the data catalog (for now)
- configure `Postgres` as a dependency and disable it in other services to achieve a deployment with only one DB, **OR** disable the `Postgres` dependency and leave the it enabled in the other services to have multiple DBs.

More information on these configurations may be found below in the **Configurable Parameters** section, in [Chart README.md](../charts/datalab/README.md).

After having the desired configurations achieved, you can install the chart:

```
cd datalab/charts/datalab
helm upgrade --install datalab . -f values.yaml --wait
```

## Additional Configurations

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
