terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.22.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 2.15.0"
    }
  }
}

locals {
  # CloudFlare Edge IPs
  # Data source is https://www.cloudflare.com/ips/
  cloudflare_ips = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/12",
    "172.64.0.0/13",
    "131.0.72.0/22",
    "2400:cb00::/32",
    "2606:4700::/32",
    "2803:f800::/32",
    "2405:b500::/32",
    "2405:8100::/32",
    "2a06:98c0::/29",
    "2c0f:f248::/32",
  ]
}

locals {
  domain = var.cloudflare_record_name == var.cloudflare_zone_name ? var.cloudflare_record_name : "${var.cloudflare_record_name}.${var.cloudflare_zone_name}"
}

resource "aws_s3_bucket" "source" {
  # Host header should match S3 bucket name.
  # Cloudflare does not provide Host Header Override to free-ride users.
  # Therefore, we set the S3 bucket name the same as the Host header.
  bucket = local.domain
  acl = "public-read"

  website {
    index_document = var.s3_website_index_document
    error_document = var.s3_website_error_document
    redirect_all_requests_to = var.s3_website_redirect_all_requests_to
    routing_rules = var.s3_website_routing_rules
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Source: https://docs.aws.amazon.com/AmazonS3/latest/user-guide/static-website-hosting.html#add-bucket-policy-public-access
data "aws_iam_policy_document" "allow_connection_from_cloudflare" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.source.arn}/*"]

    principals {
      type = "AWS"
      identifiers = ["*"]
    }

    condition {
      test = "IpAddress"
      variable = "aws:SourceIp"
      values = local.cloudflare_ips
    }
  }
}

resource "aws_s3_bucket_policy" "allow_connection_from_cloudflare" {
  bucket = aws_s3_bucket.source.id
  policy = data.aws_iam_policy_document.allow_connection_from_cloudflare.json
}

resource "cloudflare_zone_settings_override" "settings" {
  zone_id = var.cloudflare_zone_id

  settings {
    ssl = "flexible"
  }
}

resource "cloudflare_record" "record" {
  zone_id = var.cloudflare_zone_id
  name = var.cloudflare_record_name
  type = "CNAME"
  value = aws_s3_bucket.source.website_endpoint
  proxied = true
}
