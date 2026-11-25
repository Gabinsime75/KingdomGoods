# Require the intended AWS account for the GitHub OIDC bootstrap.
variable "expected_aws_account_id" {
  description = "The AWS account ID authorized to host the GitHub OIDC resources."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.expected_aws_account_id))
    error_message = "The expected AWS account ID must contain exactly 12 digits."
  }
}

provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = [var.expected_aws_account_id]
}