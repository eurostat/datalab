variable "AWS_REGION" {
  default = "eu-central-1"
  description = "Region (AZ) where to deploy resources."
  type = string
}

variable "DOCKER_HOST" {
  default = "tcp://localhost:2375"
  type = string
}

variable "DOCKER_USERNAME" {
  default = ""
  type = string
}

variable "DOCKER_PASSWORD" {
  default = ""
  type = string
}

variable "DOCKER_IMAGES_LIST" {
  default = ["user-notification-container","keycloak-metrics-sidecar","ckan2.9"]
  type = list
}

variable "USE_ECR" {
  default = true
  type = bool
}

variable "PATH_TO_DATALAB_VALUES" {
  default = "../../charts/datalab/values.yaml"
  description = "Path to datalab chart values."
  type = string
}



