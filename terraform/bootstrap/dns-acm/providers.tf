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

# Use the prod account in Oregon for the ALB origin certificate.
provider "aws" {
  alias               = "prod_usw2"
  region              = "us-west-2"
  profile             = "kingdomgoods-prod"
  allowed_account_ids = ["209479272473"]
}

# Use the dev account in Oregon for the dev ALB origin certificate.
provider "aws" {
  alias               = "dev_usw2"
  region              = "us-west-2"
  profile             = "kingdomgoods-dev"
  allowed_account_ids = ["941377138351"]
}