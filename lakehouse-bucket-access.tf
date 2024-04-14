################################################################################
# Lakehouse IAM Role
################################################################################

resource "aws_iam_role" "lakehouse_role" {
  name = local.lakehouse_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "${module.eks.oidc_provider}:sub" : [
              "system:serviceaccount:iomete-system:*",
            ]
          },
          StringEquals = {
            "${module.eks.oidc_provider}:aud" : "sts.amazonaws.com"
          }
        }
      },
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "lakehouse_bucket_access" {
  name = "${local.lakehouse_role_name}-lakehouse-bucket-access-policy"
  role = aws_iam_role.lakehouse_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteObject",
          "s3:GetObjectVersion",
        ]
        Resource = "arn:aws:s3:::${var.lakehouse_bucket_name}/*"
      },
      {

        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.lakehouse_bucket_name}"
      },
    ]
  })
}