# IOMETE Data-Plane module

This module creates a data-plane infrastructure for IOMETE on your AWS account. 

The module is open-source and available on GitHub: https://github.com/iomete/terraform-aws-iomete-data-plane

Terraform Registry: https://registry.terraform.io/modules/iomete/iomete-data-plane/aws/latest


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
provider "aws" {
  # AWS region where cluster will be created
  region = "us-east-1"
}

module "iomete-data-plane" {
  source                = "iomete/iomete-data-plane/aws"
  version               = "~> 1.9.0"
  # Cluster name. EKS cluster and other resource names will be prefixed with this name.
  cluster_name          = "lakehouse-dev"
  # Create an S3 bucket in the same region as the EKS cluster and provide the name here.
  lakehouse_bucket_name = "lakehouse-dev"
}

################# 
# Outputs 
#################

output "eks_update_kubeconfig_command" {
  value       = module.iomete-data-plane.eks_update_kubeconfig_command
}
```

###  Run terraform

Once you have the terraform file, and configured it according to your needs, you can run the following commands to create the data-plane infrastructure:

```shell
# Initialize Terraform
terraform init -upgrade

# Create a plan to see what resources will be created
terraform plan

# Apply the changes to your AWS account
terraform apply
```


Please, make sure terraform state files are stored on a secure location. State can be stored in a git, S3 bucket, or any other secure location. 
See here [Managing Terraform State – Best Practices & Examples](https://spacelift.io/blog/terraform-state) for more details.

