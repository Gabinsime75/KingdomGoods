# Place one public, application, and data subnet in each selected dev AZ.
locals {
  dev_subnets_by_az = {
    "usw2-az2" = {
      public      = "10.40.0.0/24"
      application = "10.40.16.0/20"
      data        = "10.40.64.0/24"
    }
    "usw2-az1" = {
      public      = "10.40.1.0/24"
      application = "10.40.32.0/20"
      data        = "10.40.65.0/24"
    }
    "usw2-az3" = {
      public      = "10.40.2.0/24"
      application = "10.40.48.0/20"
      data        = "10.40.66.0/24"
    }
  }
}

resource "aws_subnet" "public" {
  for_each = local.dev_subnets_by_az

  vpc_id               = aws_vpc.dev.id
  availability_zone_id = each.key
  cidr_block           = each.value.public

  tags = {
    Name                     = "kingdomgoods-dev-public-${each.key}"
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "application" {
  for_each = local.dev_subnets_by_az

  vpc_id               = aws_vpc.dev.id
  availability_zone_id = each.key
  cidr_block           = each.value.application

  tags = {
    Name                              = "kingdomgoods-dev-app-${each.key}"
    Tier                              = "application"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "data" {
  for_each = local.dev_subnets_by_az

  vpc_id               = aws_vpc.dev.id
  availability_zone_id = each.key
  cidr_block           = each.value.data

  tags = {
    Name = "kingdomgoods-dev-data-${each.key}"
    Tier = "data"
  }
}