# Publish the ACM validation CNAME for the single origin hostname.
locals {
  prod_alb_origin_validation = one(aws_acm_certificate.prod_alb_origin.domain_validation_options)
}

resource "aws_route53_record" "prod_alb_origin_validation" {
  provider = aws.management

  zone_id = aws_route53_zone.public.zone_id
  name    = local.prod_alb_origin_validation.resource_record_name
  type    = "CNAME"
  ttl     = 300
  records = [local.prod_alb_origin_validation.resource_record_value]
}

# Request the TLS certificate for the connection from CloudFront to the prod ALB.
resource "aws_acm_certificate" "prod_alb_origin" {
  provider = aws.prod_usw2

  domain_name       = "origin.kingdomgoods.store"
  validation_method = "DNS"
  key_algorithm     = "RSA_2048"

  options {
    export = "DISABLED"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Wait for ACM to issue the prod ALB origin certificate.
resource "aws_acm_certificate_validation" "prod_alb_origin" {
  provider = aws.prod_usw2

  certificate_arn = aws_acm_certificate.prod_alb_origin.arn
  validation_record_fqdns = [
    aws_route53_record.prod_alb_origin_validation.fqdn
  ]
}