# Adopt the existing DNS validation records for the CloudFront certificate.
locals {
  viewer_validation_records = {
    apex = {
      name  = "_4c5bdf1f2b140fb7c2fc1673edc6751d.kingdomgoods.store"
      value = "_ed3c4345d2491b41d53d221280320957.wzccmgtwzk.acm-validations.aws."
    }
    www = {
      name  = "_2c935442ea9f453f9ec7a63599362167.www.kingdomgoods.store"
      value = "_ba656611f0f6bf19918ca1791f81882d.wzccmgtwzk.acm-validations.aws."
    }
  }
}

resource "aws_route53_record" "viewer_validation" {
  for_each = local.viewer_validation_records
  provider = aws.management

  zone_id = aws_route53_zone.public.zone_id
  name    = each.value.name
  type    = "CNAME"
  ttl     = 300
  records = [each.value.value]
}

import {
  for_each = local.viewer_validation_records
  to       = aws_route53_record.viewer_validation[each.key]

  identity = {
    zone_id = "Z099145331H3GSTZWRJJD"
    name    = each.value.name
    type    = "CNAME"
  }
}