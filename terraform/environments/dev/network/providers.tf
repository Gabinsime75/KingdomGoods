# Restrict network provisioning to the KingdomGoods dev account.
provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["941377138351"]

  default_tags {
    tags = {
      Project     = "KingdomGoods"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}