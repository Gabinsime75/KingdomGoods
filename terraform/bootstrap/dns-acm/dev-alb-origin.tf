# Request the TLS certificate for the dev ALB origin in us-west-2.
resource "aws_acm_certificate" "dev_alb_origin" {
  provider = aws.dev_usw2

  domain_name       = "dev-origin.kingdomgoods.store"
  validation_method = "DNS"
  key_algorithm     = "RSA_2048"

  options {
    export = "DISABLED"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Publish the ACM validation CNAME for the dev origin.
locals {
  dev_alb_origin_validation = one(aws_acm_certificate.dev_alb_origin.domain_validation_options)
}

resource "aws_route53_record" "dev_alb_origin_validation" {
  provider = aws.management

  zone_id = aws_route53_zone.public.zone_id
  name    = local.dev_alb_origin_validation.resource_record_name
  type    = "CNAME"
  ttl     = 300
  records = [local.dev_alb_origin_validation.resource_record_value]
}

# Wait for ACM to issue the certificate in the dev account.
resource "aws_acm_certificate_validation" "dev_alb_origin" {
  provider = aws.dev_usw2

  certificate_arn         = aws_acm_certificate.dev_alb_origin.arn
  validation_record_fqdns = [aws_route53_record.dev_alb_origin_validation.fqdn]
}