# Store bootstrap state in S3 with native state locking.
terraform {
  backend "s3" {
    region       = "us-west-2"
    key          = "bootstrap/terraform-backend/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}