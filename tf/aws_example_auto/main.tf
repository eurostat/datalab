################################################################################
# Developer notes
# - create VPC flow logs resource in non-dev environment
# - enable control plane logs for EKS in non-dev environment
# - launch template is created to use IMDSv2 (no launch config used from the 
#   module) you can ignore the terrascan warning
################################################################################


################################################################################
# Actual provider and locals
################################################################################

provider "aws" {
  region = local.region
}

locals {
  name            = "${var.CLUSTER_PREFIX}-eks-lab"
  cluster_version = "1.20"
  region          = var.AWS_REGION
}

################################################################################
# Security Group (for IPs with access to cluster)
################################################################################

#module "web_server_sg" {
#  source = "terraform-aws-modules/security-group/aws//modules/http-80"
#
#  name        = "cluster-sg"
#  description = "Security group for eks cluster within VPC"
#  vpc_id      = module.vpc.vpc_id
#
#  ingress_cidr_blocks = var.ALLOWED_IPS
#}

################################################################################
# EKS Module
################################################################################

module "eks" {
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws
  source = "terraform-aws-modules/eks/aws"
  version = "17.24.0"

  # required arguments
  cluster_name    = local.name
  cluster_version = local.cluster_version

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  # only nodes with a certain security group can have private API access
  cluster_endpoint_private_access = true
  #cluster_create_endpoint_private_access_sg_rule = true
  #cluster_endpoint_private_access_sg = [module.web_server_sg.security_group_id]

  # public API is available to all within the CIDR
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = concat(var.ALLOWED_IPS, var.EXTRA_ALLOWED_IPS)

  # More on logs https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  # cluster_enabled_log_types = ["api","audit","authenticator","controllerManager","scheduler"]

  # Managed worker node groups defaults overwrite
  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50

    update_config = {
      max_unavailable_percentage = 50
    }

    # require IMDSv2 to avoid SSRF
    create_launch_template = true
    metadata_http_endpoint = "enabled"
    metadata_http_tokens = "required"
  }

  # Managed worker node groups
  node_groups = {
    # envisioned for the central services
    managed_worker_group_1 = {
      desired_capacity = 2
      max_capacity     = 2
      min_capacity     = 1

      instance_types = ["t3.large"]

      k8s_labels = {
        Cluster = local.name
        GitHubRepo = var.CLUSTER_PREFIX
        Environment  = var.ENVIRONMENT
        PodTenancy = "multi-tenant"
      }
    }

    # envisioned for the on-demand services
    managed_worker_group_2 = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t3.large"]
      
      k8s_labels = {
        Cluster = local.name
        GitHubRepo = var.CLUSTER_PREFIX
        Environment  = var.ENVIRONMENT
        PodTenancy = "single-tenant"
      }
    }
  }

  # base iam path for generated roles
  iam_path     = "/${var.CLUSTER_PREFIX}/"

  # additional users and roles to add to the auth config map
  map_users    = var.MAP_USERS
  map_roles    = var.MAP_ROLES

  # don't write kubeconfig
  write_kubeconfig = false

  tags = {
    Cluster = local.name
    GitHubRepo = var.CLUSTER_PREFIX
    Environment  = var.ENVIRONMENT
  }
}

################################################################################
# Kubernetes provider configuration
################################################################################

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

################################################################################
# Supporting Resources
################################################################################

data "aws_availability_zones" "available" {
}


module "vpc" {
  # https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name                 = local.name
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  # Single NAT gateway to be placed in the first public AZ - creates an Elastic IP
  enable_nat_gateway   = true
  single_nat_gateway   = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }

  tags = {
    Cluster = local.name
    GitHubRepo = var.CLUSTER_PREFIX
    Environment  = var.ENVIRONMENT
  }
}


provider "helm" {
  kubernetes {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  }
}


 provider "acme" {
    server_url = "https://acme-v02.api.letsencrypt.org/directory"
 }

data "aws_route53_zone" "validation" {
  name = "${var.DOMAINNAME}"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.EMAIL}"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = "${acme_registration.registration.account_key_pem}"
  common_name               = "${var.DOMAIN_NAME_PREFIX}.${var.DOMAINNAME}"
  subject_alternative_names = ["*.${var.DOMAIN_NAME_PREFIX}.${var.DOMAINNAME}"]
  

  dns_challenge {
    provider = "route53"

    config = {
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.validation.zone_id
    }
  }

  depends_on = [acme_registration.registration]
}


resource "helm_release" "ingress" {
  name       = "nginx-controller"
  chart      = "../../charts/ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  values = [
    "${file("../../charts/ingress-nginx/values.yaml")}"
  ]

  set {
    name = "loadBalancerSourceRanges"
    value = "{${join(",", concat(var.INGRESS_ALLOWED_IPS,module.vpc.nat_ids))}}"
  }

  set {
    name  = "clusterName"
    value = local.name
  }

  depends_on = [module.eks]
}

resource "kubernetes_secret" "secretTLS" {
  metadata {
    name = "wildcard"
    namespace = "ingress-nginx"
  }
  

  data = {
    "tls.crt" = "${lookup(acme_certificate.certificate, "certificate_pem")}"
    "tls.key" = "${lookup(acme_certificate.certificate, "private_key_pem")}"
  }

  type = "kubernetes.io/tls"
  depends_on = [helm_release.ingress]
}  


data "kubernetes_service" "example" {
  metadata {
    name = "nginx-controller-ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.ingress]
}


#resource "aws_route53_record" "example" {
#  zone_id = "${data.aws_route53_zone.validation.zone_id}"
#  name    = "${var.DOMAIN_NAME_PREFIX}.${var.DOMAINNAME}"
#  type    = "A"
#  #ttl     = "300"
#
#  alias {
#    name                   = data.kubernetes_service.example.status.0.load_balancer.0.ingress.0.hostname
#    #zone_id                = "${data.aws_route53_zone.validation.zone_id}" # get hosted zone id from load balancer
#    zone_id                = local.region
#    evaluate_target_health = true
#  }
#
#  allow_overwrite = true
#
#  depends_on = [data.kubernetes_service.example]
#}

resource "aws_route53_record" "example2" {
  zone_id = "${data.aws_route53_zone.validation.zone_id}"
  name    = "*.${var.DOMAIN_NAME_PREFIX}.${var.DOMAINNAME}"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.example.status.0.load_balancer.0.ingress.0.hostname]

  allow_overwrite = true

  depends_on = [data.kubernetes_service.example]
}


resource "helm_release" "datalab" {
  name       = "datalab"
  chart      = "../../charts/datalab"
  namespace  = "default"

  values = [
    "${file("../../charts/datalab/values.yaml")}"
  ]

  wait = false
  force_update = true
  
  
  #depends_on = [aws_route53_record.example, aws_route53_record.example2]
  depends_on = [aws_route53_record.example2]
}



