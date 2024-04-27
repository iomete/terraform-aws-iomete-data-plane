################################################################################
# KMS Key Access
################################################################################
# When using Region EBS, access to the KMS key becomes necessary because the EBS CSI driver
# encrypts the volumes it creates. To ensure these volumes function correctly, AWS EKS requires
# the ability to decrypt them. Therefore, we must set up the necessary permissions to
# access the KMS key for decryption operations.
# If Region EBS is not enabled, you can skip this configuration.
# For more details on setting up the CSI IAM role, see:
# https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html

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