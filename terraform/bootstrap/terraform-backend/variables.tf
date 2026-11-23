# Inputs for the KingdomGoods state backend bootstrap.
variable "expected_aws_account_id" {
  description = "The AWS account ID authorized to host this state backend."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.expected_aws_account_id))
    error_message = "The expected AWS account ID must contain exactly 12 digits."
  }
}