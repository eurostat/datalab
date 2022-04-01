terraform {
  required_version = ">= 0.13.1"

  backend "s3" {
  }

  required_providers {
    aws        = "4.5.0"
    local      = ">= 1.4"
    random     = ">= 2.1"
    kubernetes = "~> 2.0"
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.5.3"
    }
  }
}