terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.37.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 2.20.0"
    }
  }
}

locals {
  domain = var.cloudflare_record_name == var.cloudflare_zone_name ? var.cloudflare_record_name : "${var.cloudflare_record_name}.${var.cloudflare_zone_name}"
}

resource "aws_cloudfront_origin_access_identity" "sink" {
}

resource "aws_s3_bucket" "source" {
  bucket = local.domain
  acl = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "allow_sink_fetching" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.source.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.sink.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "source" {
  bucket = aws_s3_bucket.source.id
  policy = data.aws_iam_policy_document.allow_sink_fetching.json
}


resource "random_string" "origin_id" {
  keepers = {
    domain = aws_s3_bucket.source.bucket_regional_domain_name
  }

  length = 8
  lower = true
  special = false
  upper = false
}

resource "aws_acm_certificate" "cert" {
  domain_name = local.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name = each.value.name
  type = each.value.type
  value = each.value.record
  proxied = false
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
}

resource "aws_cloudfront_distribution" "sink" {
  origin {
    domain_name = aws_s3_bucket.source.bucket_regional_domain_name
    origin_id = random_string.origin_id.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.sink.cloudfront_access_identity_path
    }
  }

  enabled = true
  default_root_object = var.cloudfront_default_root_object
  aliases = [local.domain]
  price_class = "PriceClass_100"

  custom_error_response {
    error_code = "404"
    response_page_path = var.cloudfront_404_error_resource
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET"]
    target_origin_id = random_string.origin_id.id

    compress = true
    max_ttl = 0
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
      headers = []
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method = "sni-only"
  }
}

resource "cloudflare_zone_settings_override" "settings" {
  zone_id = var.cloudflare_zone_id

  settings {
    ssl = "strict"
  }
}

resource "cloudflare_record" "record" {
  zone_id = var.cloudflare_zone_id
  name = var.cloudflare_record_name
  type = "CNAME"
  value = aws_cloudfront_distribution.sink.domain_name
  proxied = true
}
