# Terraform requirements and remote state for GitHub OIDC.
terraform {
  required_version = "~> 1.17.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    region       = "us-west-2"
    key          = "bootstrap/github-oidc/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}