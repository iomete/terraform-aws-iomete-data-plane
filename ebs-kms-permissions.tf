################################################################################
# KMS key access?
################################################################################
# If region EBS is enabled, we need access to the KMS key. 
# This is because the EBS CSI driver will create encrypted volumes, and we need to be able to decrypt them.
# If region EBS is not enabled, you can skip this section.
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html

resource "aws_iam_policy_attachment" "kms_describe_attachment" {
  count      = var.kms_key_arn != "null" ? 1 : 0
  name       = "kms-describe-attachment"
  # Attach the kms-access-policy to the following roles
  roles      = [module.karpenter.irsa_name, module.eks.eks_managed_node_groups["${var.cluster_name}-ng"].iam_role_name, "AmazonEKS_EBS_CSI_DriverRole-${var.cluster_name}"]
  policy_arn = aws_iam_policy.kms_access_policy[0].arn
}

resource "aws_iam_policy" "kms_access_policy" {
  count       = var.kms_key_arn != "null" ? 1 : 0
  name        = "kms-access-policy"
  description = "Allows access to the KMS key"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEncryptDecrypt",
      "Effect": "Allow",
      "Action": [
        "kms:*"
      ],
      "Resource": "${var.kms_key_arn}"
    }
  ]
}
EOF
}