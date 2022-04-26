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

variable "DOMAIN_NAME" {
  description = "Domain Name to access the cluster."
  type = string
}

variable "DOMAIN_NAME_HOSTED_ZONE" {
  description = "Domain Name addressed in Hosted Zone."
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

variable "PATH_TO_NGINX_CONTROLLER_CHART" {
  default = "../../charts/ingress-nginx"
  description = "Path to nginx controller chart."
  type = string
}

variable "PATH_TO_NGINX_CONTROLLER_VALUES" {
  default = "../../charts/ingress-nginx/values.yaml"
  description = "Path to nginx controller chart values."
  type = string
}
variable "PATH_TO_DATALAB_VALUES" {
  default = "../../charts/datalab/values.yaml"
  description = "Path to datalab chart values."
  type = string
}

variable "PATH_TO_DATALAB_CHART" {
  default = "../../charts/datalab"
  description = "Path to datalab chart."
  type = string
}

variable "PATH_TO_CERTIFICATE_CRT" {
  description = "Path to certificate pem."
  type = string
  default = ""
}

variable "PATH_TO_CERTIFICATE_KEY" {
  description = "Path to certificate key."
  type = string
  default = ""
}