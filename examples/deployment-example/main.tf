module "data-plane-aws" {
#  source  = "iomete/data-plane-aws/aws"
#  version = "2.2.0"
  source                    = "../.." # for local testing

  # AWS region where cluster will be created
  region                    = "us-east-1"

  # A bucket name for IOMETE lakehouse. It should be unique withing compatible with AWS naming conventions.
  lakehouse_bucket_name     = "iom-test-lake"

  # Cluster name. EKS cluster and other resource names will be prefixed with this name.
  cluster_name              = "test-deployment"
}

#################
# Outputs
#################

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = module.data-plane-aws.cluster_name
}