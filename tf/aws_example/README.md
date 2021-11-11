# Terraform AWS Example

This example features the creation of a Kubernetes Cluster with AWS EKS. In this templates it is created:
- [VPC (Virtual Private Cloud)](https://aws.amazon.com/vpc/) with the [vpc module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
- [EKS (Elastic Kubernetes Service)](https://aws.amazon.com/eks/) with the [eks module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest).

Note that the input variables defined in `vars.tf` have to be passed during deployment. The Kubernetes API is set to filter on the CIDRs passed through the variables `ALLOWED_IPS` and `EXTRA_ALLOWED_IPS`, so ensure to whitelist the IPs of the developers (e.g., `XXX.XXX.XXX.XXX/32`).