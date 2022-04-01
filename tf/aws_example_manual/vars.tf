variable "AWS_REGION" {
  default = "eu-central-1"
}

variable "CLUSTER_PREFIX" {
  description = "Prefix for your cluster name."
}

variable "ENVIRONMENT" {
  default = "dev"
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
