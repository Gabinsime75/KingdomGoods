provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = [var.expected_aws_account_id]
}