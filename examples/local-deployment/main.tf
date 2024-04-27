module "iomete-data-plane" {
  source                    = "../.." # for local testing

  # AWS region where cluster will be created
  region                    = "us-east-1"

  # A bucket name for IOMETE lakehouse. It should be unique withing compatible with AWS naming conventions.
  lakehouse_bucket_name     = "iom-test-lake1"

  # Cluster name. EKS cluster and other resource names will be prefixed with this name.
  cluster_name              = "test-deployment1"

  cluster_administrators = [ "arn:aws:iam::680330367469:user/vusal", "arn:aws:iam::680330367469:user/fuad" ]
}

#################
# Outputs
#################

output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = module.iomete-data-plane.cluster_name
}