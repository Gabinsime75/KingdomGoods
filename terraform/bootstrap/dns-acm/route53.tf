# Adopt the existing public DNS zone in the management account.
resource "aws_route53_zone" "public" {
  provider = aws.management
  name     = "kingdomgoods.store"
  comment  = ""

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = aws_route53_zone.public
  id = "Z099145331H3GSTZWRJJD"
}