provider "aws" {
  region = var.region
}

resource "random_id" "random" {
  byte_length = 3
}

locals {
  module_version        = "1.1.0"
  data_plane_base_version    = "2.0.0"
  lakehouse_bucket_name = var.lakehouse_bucket_name != "" ? var.lakehouse_bucket_name : "${var.cluster_name}-lakehouse"
  assets_bucket_name    = "${var.cluster_name}-assets-${random_id.random.hex}"
  lakehouse_role_name   = "${var.cluster_name}-lakehouse-role"

  tags = {
    "iomete.com/cluster_name" : var.cluster_name
    "iomete.com/terraform" : true
    "iomete.com/managed" : true
  }
}
