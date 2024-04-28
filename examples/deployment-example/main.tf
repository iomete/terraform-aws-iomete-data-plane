provider "aws" {
  # AWS region where cluster will be created
  region = "us-east-1"
}

module "iomete-data-plane" {
  source                = "iomete/iomete-data-plane/aws"
  version               = "~> 1.9.0"

  # Cluster name. EKS cluster and other resource names will be prefixed with this name.
  cluster_name              = "test-deployment"

  # Create an S3 bucket in the same region as the EKS cluster and provide the name here.
  lakehouse_bucket_name     = "iom-test-lake"
}

#################
# Outputs
#################

output "eks_update_kubeconfig_command" {
  value       = module.iomete-data-plane.eks_update_kubeconfig_command
}