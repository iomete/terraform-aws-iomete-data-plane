data "aws_region" "current" {}

locals {
  module_version        = "1.9.3"
  lakehouse_role_name   = "${var.cluster_name}-lakehouse-role"

  tags = {
    "iomete.com/cluster_name" : var.cluster_name
    "iomete.com/terraform" : true
    "iomete.com/managed" : true
    "iomete.com/terraform_module_version" : local.module_version
  }
}
