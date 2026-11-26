variable "state_kms_key_arn" {
  description = "ARN of the KMS key that encrypts the dev Terraform state bucket."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:aws:kms:us-west-2:${var.expected_aws_account_id}:key/[0-9a-f-]{36}$", var.state_kms_key_arn))
    error_message = "Provide the dev state KMS key ARN in us-west-2."
  }
}
# Scope GitHub Actions access to the dev network state and lock objects.
locals {
  state_bucket_arn  = "arn:aws:s3:::kingdomgoods-tfstate-${var.expected_aws_account_id}-us-west-2"
  network_state_key = "dev/network/terraform.tfstate"
}

resource "aws_iam_role_policy" "github_terraform_state" {
  name = "dev-network-terraform-state"
  role = aws_iam_role.github_terraform.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListNetworkStatePrefix"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = local.state_bucket_arn
        Condition = {
          StringLike = {
            "s3:prefix" = "dev/network/*"
          }
        }
      },
      {
        Sid      = "ReadWriteNetworkState"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${local.state_bucket_arn}/${local.network_state_key}"
      },
      {
        Sid      = "ManageNetworkStateLock"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.state_bucket_arn}/${local.network_state_key}.tflock"
      },
    {
        Sid      = "UseStateKeyThroughS3"
        Effect   = "Allow"
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:GenerateDataKey"]
        Resource = var.state_kms_key_arn
        Condition = {
          StringEquals = {
            "kms:ViaService"                   = "s3.us-west-2.amazonaws.com"
            "kms:EncryptionContext:aws:s3:arn" = local.state_bucket_arn
          }
        }
      }
    ]
  })
}