# Infrastructure deployment and environment preparation

In this section we will be deploying the infrastructure and preparing the environment for the data lab deployment. It is recommended to review all the [Prerequisites](#prerequisites) in order to ensure a proper installation of the infrastructure. 

If you wish to deploy the ingress controler and the TLS wild card separately, please follow [the Infrastructure deployment and enviroment preparation - manual documentation](DEPLOYMENT-MANUAL.md). If you have already a running cluster, you will follow the [manual deployment](DEPLOYMENT-MANUAL.md) and you can start the deployment from the [Network](DEPLOYMENT-MANUAL.md#network) section in the manual steps.


### Prerequisites

- [Kubernetes 1.20+](https://kubernetes.io/releases)
- [Helm 3](https://helm.sh/docs/intro/install/)
- [AWS client](https://aws.amazon.com/cli/)
- [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- PV provisioner support in the underlying infrastructure
- Domain name and hosted zone
- Object storage bucket to store the Terraform state

It is recommended that you clone the [repository](https://github.com/eurostat/datalab) in order to have everything available locally. The template can be found within the source code of this project under the `tf/aws_example_auto_env` folder. 

Before installation, it is necessary to ensure that you have acquired a domain name (does not have to be from AWS), and a hosted zone, on [AWS Route53](https://aws.amazon.com/pt/route53/), for the respective domain name. 

This template automatically installs the infrastructure and prepares the environment, performing the following steps:

 - Creates a [VPC (Virtual Private Cloud)](https://aws.amazon.com/vpc/) with the [vpc module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
 - Creates a [EKS (Elastic Kubernetes Service)](https://aws.amazon.com/eks/) with the [eks module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest).
 - Manages a Route53 Hosted Zone - <b>prior creation of a hosted zone on AWS Route53 is required.</b>
 - Creates a Kubernetes Secret, using the [kubernetes_secret resource](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret), with the private key and the certificate chain of the certificate we indicate in the `dev.tfvars` file.
 - Installs the [nginx-controller](https://kubernetes.github.io/ingress-nginx/) Helm Chart. The repository must be local. Uses a `values.yaml` file to configure all necessary settings, such as indicating the use of AWS Network Load Balancer (NLB) as the Service Type Load Balancer and pointing the `default-ssl-certificate` option to the secret created.
 - Automatically creates a wildcard CNAME record in the hosted zone that points to the NLB, using the [AWS Route53 Record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record). The name will be of the following format: `*.DOMAIN_NAME`.

Of the resources mentioned above the following are not cloud agnostic:

1. [AWS EKS](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
2. [AWS VPC](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
3. [AWS Route53 Record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)
4. [NGINX Ingress controller](https://kubernetes.github.io/ingress-nginx/)

We also use an S3 bucket to store the Terraform state, so that developers can individually update the AWS resources without conflicts. Extra support on the remote backend feature for Terraform can be found on the [official Terraform documentation](https://www.terraform.io/docs/language/settings/backends/remote.html).

> You will need to create the S3 bucket backend, or have access to a pre-existing bucket. The key of the Terraform state file can be written with a prefix (e.g., `tfstates/datalab-state-dev`). 

As it should be noticeable, these resources could be adapted to any other cloud provider. AWS EKS have similar services in most cloud providers, and Terraform has resources for the majority of them, as can be consulted [here](https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider).

For the VPC, the situation is similar to EKS, but cloud providers have a more specific configuration for network, which means this resource should be configured as such.

In the context of DNS Providers, if they are hosted in a cloud provider, then Terraform will have resources to dynamically change them, such as [azurerm_dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone) for Azure. But if the domain is hosted in an external DNS Provider to the cloud, than this step can be hard to automate, however, there is still the option of taking this resource out of the template and process this step manually.

Finally, the NGINX Ingress controller could be substituted by any cloud Load Balancer, be used according to the [Kubernetes environment](https://kubernetes.github.io/ingress-nginx/deploy/), or even be replaced by [traefik](https://traefik.io/), as was stated above. If it is decided to use a version of NGINX Ingress controller according to the cloud provider, the simple replacement of the helm chart under the folder `charts` could be made to accomplish the objective.

To deploy on AWS ensure you have the authentication taken care of in the [AWS CLI (Command Line Interface)](https://aws.amazon.com/cli/) with the right credentials, and inside the `tf/aws_example_auto_env/` folder create a file called `dev.tfvars` in which you will place the variable configurations as requested in `vars.tf`. For example:
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
PATH_TO_CERTIFICATE_CRT = ""
PATH_TO_CERTIFICATE_KEY = ""
```
As you can see above, the variables allow us to:
<li><b>AWS_REGION</b>: indicate the region in AWS where you want to deploy the resources. </li>
<li><b>CLUSTER_PREFIX</b>: define the EKS cluster prefix name, if the given prefix is "estat", the cluster will be called "estat-eks-lab". It cannot exceed 5 characters. </li>
<li><b>ENVIRONMENT</b>: environment where the data lab will be deployed, whether "dev" or "prod".</li>
<li><b>MAP_USERS</b>: AWS users that will be able to manage the EKS cluster.</li>
<li><b>MAP_ROLES</b>: AWS roles that will be able to manage the EKS cluster.</li>
<li><b>ALLOWED_IPS</b>: IPs that will be able to manage the EKS cluster.</li>
<li><b>EXTRA_ALLOWED_IPS</b>: extra IPs that will be able to manage the EKS cluster.</li>
<li><b>DOMAIN_NAME</b>: domain which the data lab will be deployed.</li>
<li><b>DOMAIN_NAME_HOSTED_ZONE</b>: AWS domain hosted zone.</li>
<li><b>EMAIL</b>: e-mail that will be used to be communicated when the TLS certificate expire.</li>
<li><b>INGRESS_ALLOWED_IPS</b>: IPs that will be able to acces the ingress controller.</li>
<li><b>PATH_TO_NGINX_CONTROLLER_CHART</b>: indicate the location of the Helm charts we need for the nginx-controller installation.</li>
<li><b>PATH_TO_NGINX_CONTROLLER_VALUES</b>: the respective path to the nginx-controller configuration file.</li>
<li><b>PATH_TO_CERTIFICATE_CRT</b>: the path to the certificate.</li>
<li><b>PATH_TO_CERTIFICATE_KEY</b>: the path to the certificate key.</li><br>

The default values file ​​for the nginx-controller variables is set to the path where this chart and configuration is found if you clone the [Data Lab repository](https://github.com/eurostat/datalab). 

To add the certificate to our implementation we have two options:<br>
   1. In the first one, we create the certificate in advance, following the instructions in the [Network](DEPLOYMENT-MANUAL.md#network) session in the Manual deployment, and then we change the variables `PATH_TO_CERTIFICATE_CRT` and `PATH_TO_CERTIFICATE_KEY` to the directory where the certificate files are stored.
   2. In the second, a TLS Certificate, available for all the sub-domains required by the Data Lab, is created during the execution of the terraform template. This option uses [Let's Encrypt](https://letsencrypt.org/) as the Certificate Authority, and [ACME](https://registry.terraform.io/providers/vancluever/acme/latest/docs) to automate the certificates generation. To use this option, you must not define the two variables, `PATH_TO_CERTIFICATE_CRT` and `PATH_TO_CERTIFICATE_KEY`, so that they have their default values, that is, equal to `""`.

Finally, after having all the configurations completed, and [Terraform Plan](https://www.terraform.io/cli/commands/plan) reviewed, a bucket or file structure to save the [Terraform State](https://www.terraform.io/language/state) should already be in place, so that the following commands run successfully:

```
terraform init -backend-config="bucket=************" -backend-config="key=************" -backend-config="region=************"

terraform apply -var-file="dev.tfvars"
```
On <i>bucket</i>, you will put the name of the <b>S3 bucket</b> created, on <i>key</i> the name of the <b>Terraform state file</b> and finally, the region is the region where all the AWS resources will be deployed (e.g.: <i>eu-central-1</i>). 

After deployment, to configure your developer [kubectl](https://kubernetes.io/docs/tasks/tools/), use the AWS CLI to run the command to update your kubeconfig as described on [AWS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html):

```
aws eks --region eu-central-1 update-kubeconfig --name <cluster_name>
```

> There are numerous advantages of having the EKS cluster being created and deleted continuously during the development stage on-off hours (off work schedule), the most important being the reduction of costs. To achieve this workflow, you can take a look at the automatic procedure to start the EKS cluster by 8h00 (GMT) and delete it by 19h00 (GMT) from Monday to Friday in [`.github/example_workflows`](../.github/example_workflows).

After all the resources have been created successfully, the data lab is ready to be deployed following [the Data lab installation documentation](DATALAB-INIT.md).
