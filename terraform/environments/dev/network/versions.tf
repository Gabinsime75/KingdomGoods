# Terraform requirements and remote state for the KingdomGoods dev network.
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
    key          = "dev/network/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}