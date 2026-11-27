# Use management for Route 53 and prod us-east-1 for CloudFront ACM.
provider "aws" {
  alias               = "management"
  region              = "us-east-1"
  profile             = "kingdomgoods-management"
  allowed_account_ids = ["303319466234"]
}

provider "aws" {
  alias               = "prod_use1"
  region              = "us-east-1"
  profile             = "kingdomgoods-prod"
  allowed_account_ids = ["209479272473"]
}