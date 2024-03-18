resource "aws_secretsmanager_secret" "api_waf_secret" {
  #checkov:skip=CKV_AWS_149:Key is kept in the secret manager
  name                    = "api-waf-secret"
  recovery_window_in_days = 0
  
  tags                    = local.default_tags
}

resource "aws_secretsmanager_secret_rotation" "api_waf_secrets_rotation" {
  secret_id           = aws_secretsmanager_secret.api_waf_secret.id
  rotation_lambda_arn = module.api_waf_secret_rotation_lambda_function.lambda_function_arn

  rotation_rules {
    automatically_after_days = 7
  }
}

moved {
  from = module.example
  to   = module.api_waf_secrets_rotation
}