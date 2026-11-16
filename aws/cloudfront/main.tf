resource "aws_s3_bucket" "website" {
  bucket_prefix = var.bucket_prefix
}

resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_kms_key" "mykey" {
  description             = "S3 encryption key"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.id
      sse_algorithm = "aws-kms"
    }

    bucket_key_enabled = true
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "website-oac-${var.environment}"
  description                       = "Secure access to private S3 origin"

  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_cache_policy" "website" {
  name        = "website-cache-${var.environment}"
  comment     = "Static website cache policy"
  min_ttl     = 0
  default_ttl = 3600
  max_ttl     = 86400

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}


resource "aws_cloudfront_response_headers_policy" "security" {
  name    = "website-security-${var.environment}"
  comment = "Security headers for static website"

  security_headers_config {

    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}


resource "aws_cloudfront_distribution" "website" {

  enabled         = true
  is_ipv6_enabled = true

  aliases = [var.domain_name]

  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name

    origin_id = "private-s3-origin"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {

    target_origin_id = "private-s3-origin"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id = aws_cloudfront_cache_policy.website.id

    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id

    compress = true
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [
    aws_s3_bucket_versioning.website,
    aws_s3_bucket_server_side_encryption_configuration.website,
    aws_s3_bucket_public_access_block.website
  ]
}


resource "aws_s3_bucket_policy" "website" {

  bucket = aws_s3_bucket.website.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Sid    = "AllowCloudFrontReadOnly"
        Effect = "Allow"

        Principal = {
          Service = "cloudfront.amazonaws.com"
        }

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.website.arn}/*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.website
  ]
}



locals {
  website_files = fileset("${path.module}/www", "**/*")

  mime_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
    gif  = "image/gif"
    ico  = "image/x-icon"
    txt  = "text/plain"
  }
}

resource "aws_s3_object" "website_files" {

  for_each = local.website_files

  bucket = aws_s3_bucket.website.id

  key = each.value

  source = "${path.module}/www/${each.value}"

  etag = filemd5("${path.module}/www/${each.value}")

  content_type = lookup(
    local.mime_types,
    lower(element(reverse(split(".", each.value)), 0)),
    "application/octet-stream"
  )

  cache_control = endswith(each.value, ".html") ? "no-cache, max-age=0, must-revalidate" : "public, max-age=31536000"

  depends_on = [
    aws_s3_bucket_server_side_encryption_configuration.website
  ]
}

resource "aws_route53_record" "website" {

  zone_id = var.route53_zone_id

  name = var.domain_name

  type = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website_ipv6" {

  zone_id = var.route53_zone_id

  name = var.domain_name

  type = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}


