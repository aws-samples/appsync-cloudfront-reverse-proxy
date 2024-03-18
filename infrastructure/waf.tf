resource "aws_wafv2_ip_set" "ip" {
  provider           = aws.us_east_1
  name               = "allowed-ips"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = [] # list of ip addresses to allow.

  tags = local.default_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_wafv2_ip_set" "api_ip" {
  name               = "allowed-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = [] # list of ip addresses to allow.

  tags = local.default_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_wafv2_web_acl" "cloudfront_waf" {
  # checkov:skip=CKV2_AWS_31: ADD REASON
  provider    = aws.us_east_1
  name        = "cloudfront-ACL"
  description = "API firewall"
  scope       = "CLOUDFRONT"
  lifecycle {
    create_before_destroy = true
  }

  default_action {
    block {}
  }

  rule {
    name     = "ip-greenlist"
    priority = 2

    action {
      allow {}
    }

    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.ip.arn
          }
        }
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.ip.arn
            ip_set_forwarded_ip_config {
              header_name       = "X-Forwarded-For"
              fallback_behavior = "NO_MATCH"
              position          = "FIRST"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "api-ip-greenlist-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-based-rule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "api-rate-based-rule-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "API-BadInputsRuleSet-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "SizeRestrictions_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "EC2MetaDataSSRF_COOKIE"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "EC2MetaDataSSRF_QUERYARGUMENTS"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "API-CommonRuleSet-metric"
      sampled_requests_enabled   = true
    }
  }
  tags = local.default_tags
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "API-metric"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl" "api_waf" {
  # checkov:skip=CKV2_AWS_31: ADD REASON
  name        = "Api-ACL"
  description = "API firewall"
  scope       = "REGIONAL"
  lifecycle {
    create_before_destroy = true
  }

  default_action {
    block {}
  }

  rule {
    name     = "ip-greenlist"
    priority = 2

    action {
      allow {}
    }

    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.api_ip.arn
          }
        }
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.api_ip.arn
            ip_set_forwarded_ip_config {
              header_name       = "X-Forwarded-For"
              fallback_behavior = "NO_MATCH"
              position          = "FIRST"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "api-ip-greenlist-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-based-rule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "api-rate-based-rule-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "API-BadInputsRuleSet-metric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "SizeRestrictions_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "EC2MetaDataSSRF_COOKIE"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "EC2MetaDataSSRF_QUERYARGUMENTS"
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "API-CommonRuleSet-metric"
      sampled_requests_enabled   = true
    }
  }
  tags = local.default_tags
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "API-metric"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  provider          = aws.us_east_1
  # checkov:skip=CKV_AWS_158: Logs encryption
  name              = "aws-waf-logs-cloudfront"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "api_waf_log_group" {
  # checkov:skip=CKV_AWS_158: Logs encryption
  name              = "aws-waf-logs-api"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_resource_policy" "api_acl_policy" {
  policy_document = data.aws_iam_policy_document.cw_log_group_access_policy.json
  policy_name     = "api-webacl-policy-${var.region}"
}

resource "aws_wafv2_web_acl_logging_configuration" "log_group_config" {
  provider                = aws.us_east_1
  log_destination_configs = [aws_cloudwatch_log_group.log_group.arn]
  resource_arn            = aws_wafv2_web_acl.cloudfront_waf.arn
}

resource "aws_wafv2_web_acl_logging_configuration" "api_log_group_config" {
  log_destination_configs = [aws_cloudwatch_log_group.api_waf_log_group.arn]
  resource_arn            = aws_wafv2_web_acl.api_waf.arn
}