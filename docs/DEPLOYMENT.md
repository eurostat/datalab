# Deployment

To deploy the current version of the Data Lab the only requirements are a Kubernetes Cluster with an ingress controller (reverse proxy), and a domain name. If you have one, you can start the deployment from [here](#network). However, if you do not have a Kubernetes Cluster, this document guides you to the deployment of one in AWS.

## :warning: Disclaimer :warning:
The documentation is still in development and may be subject to future changes.

## Table of Contents
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
aws eks --region <region-code> update-kubeconfig --name <cluster_name>
```

> There are numerous advantages by having the EKS cluster being created and deleted continuously during the development stage on-off hours (off work schedule), the most important being the reduction of costs. To achieve this workflow, you can take a look at the automatic procedure to start the EKS cluster by 8h00 (GMT) and delete it by 19h00 (GMT) from Monday to Friday in [`.github/example_workflows`](../github/example_workflows).

The second component of the Kubernetes cluster that is necessary is the Ingress Controller. This will be done with an [NGINX Ingress controller](https://kubernetes.github.io/ingress-nginx/). We will use AWS Network Load Balancer as the Service Type Load Balancer, but this option is only available on AWS, if you want to reach an cloud agnostic Ingress Controller, you can look into other options such as [traefik](https://traefik.io/).

The simplest way to deploy it is to use the manifest provided by [Kubernetes Community](https://kubernetes.github.io/ingress-nginx/deploy/#aws)
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.4/deploy/static/provider/aws/deploy.yaml
```

## Network
CNAME, TLS

...

## Data Lab Deployment
Helm install complete package with all the initial configurations already set up.

...

## Additional Configurations

...