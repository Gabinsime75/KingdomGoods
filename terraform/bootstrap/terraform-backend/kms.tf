resource "aws_kms_key" "terraform_state" {
  description             = "Encrypts KingdomGoods Terraform state in S3"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  lifecycle {
    prevent_destroy = true
  }
}