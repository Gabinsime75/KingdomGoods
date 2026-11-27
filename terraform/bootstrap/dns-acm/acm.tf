# Adopt the issued CloudFront viewer certificate in AWS prod.
resource "aws_acm_certificate" "viewer" {
  provider = aws.prod_use1

  domain_name               = "kingdomgoods.store"
  subject_alternative_names = ["www.kingdomgoods.store"]
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"

  options {
    export = "DISABLED"
  }

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = aws_acm_certificate.viewer
  id = "arn:aws:acm:us-east-1:209479272473:certificate/877ebddd-5023-4882-8895-826389dfa252"
}