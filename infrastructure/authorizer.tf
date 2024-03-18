# Lambda Authorizer
module "appsync_lambda_authorizer" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 4.0"
  
  create_function                   = true
  function_name                     = "api-authorizer-${var.region}-${var.env}"
  description                       = "AppSync Lambda Authorizer."
  handler                           = "index.handler"
  runtime                           = "nodejs20.x"
  publish                           = true
  timeout                           = 10
  reserved_concurrent_executions    = -1
  provisioned_concurrent_executions = -1
  memory_size                       = 512
  cloudwatch_logs_retention_in_days = 30

  source_path = [
    {
      path = "${local.appsync_dir}/authorizer/index.mjs"
    }
  ]

  layers = ["arn:aws:lambda:${var.region}:094274105915:layer:AWSLambdaPowertoolsTypeScript:21"]

  environment_variables = {
    NODE_OPTIONS          = var.env != "prod" ? "--enable-source-maps" : null
    LOG_LEVEL             = var.env == "dev" ? "DEBUG" : "INFO"

  }

  tags = local.default_tags

  allowed_triggers = {
    AppSync = {
      service = "appsync"
    }
  }
}