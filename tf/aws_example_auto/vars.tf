variable "AWS_REGION" {
  default = "eu-central-1"
  description = "Region (AZ) where to deploy resources."
  type = string
}

variable "CLUSTER_PREFIX" {
  default = "estat"
  description = "Prefix for your cluster name."
  type = string
}

variable "ENVIRONMENT" {
  default = "dev"
  description = "Tag to address resources (dev/prod)."
  type = string
}

variable "MAP_USERS" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
}

variable "MAP_ROLES" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
}

variable "ALLOWED_IPS" {
  description = "User IPs that are allowed to access eks cluster."
  type = list(string)
}

variable "EXTRA_ALLOWED_IPS" {
  default = []
  description = "Extra user/machine IPs that are allowed to access eks cluster."
  type = list(string)
}

variable "DOMAINNAME" {
  description = "Domain Name to access the cluster."
  type = string
}

variable "DOMAIN_NAME_PREFIX" {
  description = "Domain Name Prefix to access the cluster."
  type = string
}

variable "EMAIL" {
  description = "Email for certificate."
  type = string
}

variable "INGRESS_ALLOWED_IPS" {
  description = "User IPs that are allowed to access ingress."
  type = list(string)
}
