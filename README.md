# IOMETE Data-Plane module

This module creates a data-plane infrastructure for IOMETE on your AWS account. 

The module is open-source and available on GitHub: https://github.com/iomete/terraform-aws-iomete-data-plane


## Data plane installation

### Pre-requisites

Make sure you have the following tools installed on your machine:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
- [Terraform CLI](https://www.terraform.io/downloads.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)


### Configure Terraform file

Create a new folder and create a file (e.g. `iomete-terraform.tf`) with the following content:

> **_Important:_**  Do not forget to change the `region`, `cluster_name`, and `lakehouse_bucket_name` values according to your needs.


```hcl
module "data-plane-aws" {
  source                    = "iomete/data-plane-aws/aws"
  version                   = "~> 2.2.0"
  # AWS region where cluster will be created
  region                    = "us-east-1"
  # Cluster name. EKS cluster and other resource names will be prefixed with this name.
  cluster_name              = "lakehouse-dev"
  # A bucket name for IOMETE lakehouse. It should be unique withing compatible with AWS naming conventions.
  lakehouse_bucket_name     = "lakehouse-dev"
}

################# 
# Outputs 
#################

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = module.data-plane-aws.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.data-plane-aws.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate cluster with the IOMETE controlplane"
  value       = module.data-plane-aws.cluster_certificate_authority_data
}
```

###  Run terraform

Once you have the terraform file, and configured it according to your needs, you can run the following commands to create the data-plane infrastructure:

```shell
# Initialize Terraform
terraform init --upgrade

# Create a plan to see what resources will be created
terraform plan

# Apply the changes to your AWS account
terraform apply
```


Please, make sure terraform state files are stored on a secure location. State can be stored in a git, S3 bucket, or any other secure location. 
See here [Managing Terraform State – Best Practices & Examples](https://spacelift.io/blog/terraform-state) for more details.

