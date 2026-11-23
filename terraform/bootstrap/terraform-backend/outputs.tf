# Values used to configure the KingdomGoods S3 backend.
output "state_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt Terraform state."
  value       = aws_kms_key.terraform_state.arn
}