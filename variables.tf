# required inputs
variable "cluster_name" {
  type        = string
  description = "A unique cluster name for IOMETE. It should be unique withing compatible with AWS naming conventions."
}

variable "lakehouse_bucket_name" {
  description = "An empty S3 bucket name for IOMETE Lakehouse. Make sure the bucket is located in the same region as the cluster."
  type        = string
}

# optional inputs
variable "eks_ng_instance_type" {
  description = "EKS main node group instance type"
  type        = string
  default     = "r5a.large"
}

variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.30"
}

variable "volume_size" {
  description = "Cluster node volume size"
  type        = string
  default     = "100"
}

variable "volume_type" {
  description = "Disk mount type"
  type        = string
  default     = "gp3"
}

variable "kms_key_arn" {
  description = "KMS key ARN to decrypt, encrypted resources (e.g. EBS volumes)"
  type        = string
  default     = "null"
}

variable "cluster_administrators" {
  description = "A list of IAM ARNs to administer IOMETE infrastructure. By default, if no ARNs are provided, the current caller identity is automatically included to ensure that there is at least one administrator. If you choose to specify ARNs, it's recommended to include the caller identity as well to maintain access."
  type        = list(string)
  default     = []
}

variable "kubernetes_public_access_cidrs" {
  description = "A list of CIDR blocks to allow access to the Kubernetes API server from. Defaults is '0.0.0.0/0' Anywhere."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "detailed_monitoring" {
  description = "Enable or disable detailed monitoring."
  type        = bool
  default     = false
}