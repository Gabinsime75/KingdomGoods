# Terraform requirements and remote state for public DNS and the CloudFront certificate.
terraform {
  required_version = "~> 1.17.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    key          = "bootstrap/dns-acm/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}