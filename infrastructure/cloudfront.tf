
locals {
  allowed_origins = concat(["https://${local.hosted_zone}"], var.env == "dev" ? ["http://localhost:4200"] : [])
}

resource "aws_s3_bucket" "backend_api_proxy_logs" {
  #checkov:skip=CKV_AWS_18: Not requied for a logging bucket
  #checkov:skip=CKV_AWS_21: "versioning not required for logs
  #checkov:skip=CKV_AWS_145: Only AES for cloudfront bucket.
  bucket = "cf-api-proxy-logs-${var.region}-${var.env}"
  tags   = local.default_tags
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.backend_api_proxy_logs.id

  depends_on = [aws_s3_bucket_public_access_block.public_access_block, aws_s3_bucket.backend_api_proxy_logs] # Need to avoid the bucket policy and access policy setting at the same time

  # Terraform's "jsonencode" function converts a
  # Terraform expression's result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "MYBUCKETPOLICY"
    Statement = [
      {
        "Sid" : "AllowSSLRequestsOnly",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          aws_s3_bucket.backend_api_proxy_logs.arn,
          "${aws_s3_bucket.backend_api_proxy_logs.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        },
        "Principal" : "*"
      },
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption_config" {
  bucket = aws_s3_bucket.backend_api_proxy_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_policy" {
  bucket = aws_s3_bucket.backend_api_proxy_logs.id

  rule {
    id = "lifecycle-rule-1"

    filter { 
        prefix = "log/"
        and {
            tags = {
                rule      = "log"
                autoclean = "true"
            }
        }
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA" 
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 180
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.backend_api_proxy_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "cloud_front_logs_logs_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.cf_api_proxy_ownership_controls]

  bucket = aws_s3_bucket.backend_api_proxy_logs.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_ownership_controls" "cf_api_proxy_ownership_controls" {
  bucket = aws_s3_bucket.backend_api_proxy_logs.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_cloudfront_response_headers_policy" "api_proxy_response" {
  name    = "api-proxy-response-header-policy"
  comment = "API proxy response header policy"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
      preload                    = true
    }

    content_security_policy {
      content_security_policy = "default-src 'self'"
      override = true
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = false
    }

    content_type_options {
      override = true
    }

    xss_protection {
      protection = true
      mode_block = true
      override   = false
    }
  }

  cors_config {
    access_control_allow_credentials = true

    access_control_allow_headers {
      items = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key", "X-Amz-Security-Token", "Cookie"]
    }

    access_control_allow_methods {
      items = ["POST", "OPTIONS"]
    }

    access_control_allow_origins {
      items = local.allowed_origins
    }

    origin_override = true
  }
}

resource "aws_cloudfront_origin_request_policy" "websockets" {
  name    = "websocket-policy"
  comment = "Policy to allow websockets"
  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Sec-WebSocket-Key", "Sec-WebSocket-Version", "Sec-WebSocket-Protocol", "Sec-WebSocket-Accept"]
    }
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_identity" {
  provider = aws.us_east_1
  comment  = "api-reverse-proxy-oai"
}

resource "aws_cloudfront_distribution" "api_proxy" {
  provider            = aws.us_east_1
  #Uncomment to enable custom domain.
  #aliases            = [local.api_domain]
  default_root_object = "index.html"
  comment             = "API reverse proxy ${local.api_domain}"
  enabled             = true
  is_ipv6_enabled     = true
  wait_for_deployment = false
  origin {
    domain_name = regex("//([^:]*)/", aws_appsync_graphql_api.backend_api.uris["GRAPHQL"])[0]
    origin_id   = "appsync-api-origin"
    custom_header {
        name  = local.waf_identity_header_name
        value = "placeholder" #Dummy value, will be replaced by a secret.
    }
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name = regex("//([^:]*)/", aws_appsync_graphql_api.backend_api.uris["REALTIME"])[0]
    origin_id   = "appsync-websocket-api-origin"
    origin_path = "/graphql"
    custom_header {
        name  = local.waf_identity_header_name
        value = "placeholder" #Dummy value, will be replaced by a secret.
    }
    custom_origin_config {
      
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.backend_api_proxy_logs.bucket_domain_name
  }

  default_cache_behavior {
    allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    target_origin_id           = "appsync-api-origin"
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.api_proxy_response.id
    min_ttl                    = 0
    default_ttl                = 300
    max_ttl                    = 300
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.set_auth_header.arn
    }
  }

  ordered_cache_behavior {
    path_pattern              = "/subscription*"
    allowed_methods           =  ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods            = ["GET", "HEAD"]
    compress                  = true
    target_origin_id          = "appsync-websocket-api-origin"
    viewer_protocol_policy    = "redirect-to-https"
    min_ttl                   = 0
    default_ttl               = 300
    max_ttl                   = 300
    cache_policy_id           = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id  = aws_cloudfront_origin_request_policy.websockets.id
     function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.set_auth_header.arn
    }
  }

  price_class = "PriceClass_100"
  web_acl_id  = aws_wafv2_web_acl.cloudfront_waf.arn

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    #acm_certificate_arn            = aws_acm_certificate.backend_api_cert.arn
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
    iam_certificate_id             = null
  }

  tags = local.default_tags
}

resource "aws_cloudfront_function" "set_auth_header" {
  name    = "setAccessTokenHeader"
  runtime = "cloudfront-js-1.0"
  comment = "Function to read access token from cookies and set authorization header for appsync api."
  publish = true
  code    = file("${path.module}/../src/cloudfront/cookie-reader.js")
}
