# Infrastructure deployment and environment preparation - manual

In this section we will be deploying the infrastructure and preparing the environment for the data lab deployment, with the deployment of ingress controller and the generation of the wild cards done manually. It is recommended to review all the [Prerequisites](#prerequisites) in order to ensure a proper installation of the infrastructure. git 

This method will allow you to have more control of all the steps necessary to set up the infrastructure and the environment, allowing a more phased installation and even the use of a previously created Kubernetes cluster. If you want an easier installation with less settings, follow the [Automatic infrastructure deployment and environment preparation](infra-env-deployment) steps.

### Prerequisites

- [Kubernetes 1.20+](https://kubernetes.io/releases)
- [Helm 3](https://helm.sh/docs/intro/install/)
- [AWS client](https://aws.amazon.com/cli/)
- [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- PV provisioner support in the underlying infrastructure
- Domain name and hosted zone
- Object storage bucket to store the Terraform state


### Kubernetes Cluster

To deploy the Kubernetes cluster a [Terraform](https://www.terraform.io/) template is used. The template creates the following AWS required resources:
 - [VPC (Virtual Private Cloud)](https://aws.amazon.com/vpc/) with the [vpc module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
 - [EKS (Elastic Kubernetes Service)](https://aws.amazon.com/eks/) with the [eks module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest).
  
This Kubernetes cluster deployment is assuming an AWS environment. It could be adapted to any other cloud provider or on premises, because most cloud providers have equivalent services to AWS EKS (e.g, [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/), [GKE](https://cloud.google.com/kubernetes-engine)), and Terraform has resources for the majority of them, as they can be consulted [here](https://learn.hashicorp.com/tutorials/terraform/kubernetes-provider). 

An S3 bucket to store the Terraform state is needed, so that developers can individually update the AWS resources without conflicts. Extra support on the remote backend feature for Terraform can be found on the [official Terraform documentation](https://www.terraform.io/docs/language/settings/backends/remote.html).

> It is needed to create the S3 bucket backend, or have access to a pre-existing bucket. The key of the Terraform state file can be written with a prefix (e.g., `tfstates/datalab-state-dev`). 

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

As you can see above, the variables allow us to:
<li><b>CLUSTER_PREFIX</b>: define the EKS cluster prefix name, if the given prefix is "estat", the cluster will be called "estat-eks-lab". It cannot exceed 5 characters. </li>
<li><b>ENVIRONMENT</b>: environment where the data lab will be deployed, whether "dev" or "prod".</li>
<li><b>MAP_USERS</b>: AWS users that will be able to manage the EKS cluster.</li>
<li><b>MAP_ROLES</b>: AWS roles that will be able to manage the EKS cluster.</li>
<li><b>ALLOWED_IPS</b>: IPs that will be able to manage the EKS cluster.</li><br>

To do the actual deployment, you can initiate the backend configuration and apply it with the newly created `dev.tfvars`:

```
terraform init -backend-config="bucket=************" -backend-config="key=************" -backend-config="region=eu-central-1"

terraform apply -var-file="dev.tfvars"
```
On <i>bucket</i>, you will put the name of the <b>S3 bucket</b> created, on <i>key</i> the name of the <b>Terraform state file</b> and finally, the region is the region where all the AWS resources will be deployed (e.g.: <i>eu-central-1</i>). 

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
Ensure the generation a certificate for your sub-domains too, for example: `example.test,*.example.test,*.kub.example.test`.

After following the instructions, set-up your Ingress controller to use your certificates. First, create a secret with the privatekey and the certificate chain:
```
kubectl create secret tls wildcard -n ingress-nginx --key privkey.pem --cert fullchain.pem
```

The Ingress controller will be our point of entrance, it will be done with an [NGINX Ingress controller](https://kubernetes.github.io/ingress-nginx/). We will use AWS Network Load Balancer as the Service Type Load Balancer, but this option is only available on AWS, if you want to reach an cloud agnostic Ingress Controller, you can look into other options such as [traefik](https://traefik.io/) to achieve full cloud agnosticity. However, there is also the option of using NGINX Ingress controller for other cloud provider, as can be consulted [here](https://kubernetes.github.io/ingress-nginx/deploy/).

The simplest way to deploy it is to use the manifest provided by [Kubernetes Community](https://kubernetes.github.io/ingress-nginx/deploy/#aws), or similar manifests.

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

After all the resources have been created successfully, the data lab is ready to be deployed following [the Data lab installation documentation](DATALAB-INIT.md).
