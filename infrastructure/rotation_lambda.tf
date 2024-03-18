module "api_waf_secret_rotation_lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name                 = "api-waf-secret-rotation"
  description                   = "Rotates the secret and updates and cloudfront origin header and WAF header rule."
  handler                       = "waf_key_rotation_function.lambda_handler"
  runtime                       = "python3.10"
  timeout                       = 300
  source_path                   = "${path.module}/../src/lambdas/waf_key_rotation_function.py"
  attach_cloudwatch_logs_policy = true
  create_current_version_allowed_triggers = false
  layers = [
    module.python_requests_layer.lambda_layer_arn,
  ]

  environment_variables = {
    WAFACLID   = aws_wafv2_web_acl.api_waf.id
    WAFACLNAME = aws_wafv2_web_acl.api_waf.name
    WAFRULEPRI = 0
    CFDISTROID = aws_cloudfront_distribution.api_proxy.id
    HEADERNAME = local.waf_identity_header_name
    ORIGINURL  = aws_appsync_graphql_api.backend_api.uris["GRAPHQL"]
    STACKNAME  = "api-waf-secret-rotation"
  }

  attach_policy_jsons    = true
  number_of_policy_jsons = 4
  policy_jsons = [
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:DescribeSecret",
            "secretsmanager:GetSecretValue",
            "secretsmanager:PutSecretValue",
            "secretsmanager:UpdateSecretVersionStage"
          ]
          Resource = [
            aws_secretsmanager_secret.api_waf_secret.arn
          ]
        }
      ]
    }),
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetRandomPassword"
          ]
          Resource = "*"
        }
      ]
    }),
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "cloudfront:GetDistribution",
            "cloudfront:GetDistributionConfig",
            "cloudfront:ListDistributions",
            "cloudfront:UpdateDistribution"
          ]
          Resource = [aws_cloudfront_distribution.api_proxy.arn]
        }
      ]
    }),
    jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "wafv2:GetWebACL",
            "wafv2:UpdateWebACL"
          ]
          Resource = [aws_wafv2_web_acl.api_waf.arn, aws_wafv2_ip_set.ip.arn]
        }
      ]
    })
  ]

  allowed_triggers = {
    SecretRotation = {
      principal  = "secretsmanager.amazonaws.com"
      source_arn = aws_secretsmanager_secret.api_waf_secret.arn
    }
  }

  tags = {
    Module = "api-waf-secret-rotation"
  }
}

module "python_requests_layer" {
  source              = "terraform-aws-modules/lambda/aws"
  version             = "4.16.0"
  create_layer        = true
  layer_name          = "requests-lambda-layer"
  description         = "Lambda layer for python requests and urllib packages."
  compatible_runtimes = ["python3.10"]
  runtime             = "python3.10"
  source_path = [
    {
      path             = "${path.module}/../src/lambdas/layer"
      pip_requirements = true     # Will run "pip install" with default "requirements.txt" from the path
      prefix_in_zip    = "python" # required to get the path correct
    }
  ]
}

moved {
  from = module.lambda_function
  to   = module.api_waf_secret_rotation_lambda_function
}
