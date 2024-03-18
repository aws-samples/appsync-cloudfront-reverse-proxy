locals {
    pipeline_resolver_code   = file("${local.appsync_dir}/functions/pipelineResolver.js")
}

# API setup
resource "aws_appsync_graphql_api" "backend_api" {
  name   = "api-${var.region}-${var.env}"
  schema = file("${local.appsync_dir}/schema.graphql")

  authentication_type = "AWS_LAMBDA"
  lambda_authorizer_config {
    authorizer_uri                   = module.appsync_lambda_authorizer.lambda_function_arn
    authorizer_result_ttl_in_seconds = 0
  }

  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.api_logs_role.arn
    field_log_level          = "ERROR"
  }

  xray_enabled = true
  tags         = local.default_tags
}

resource "aws_wafv2_web_acl_association" "api_web_acl" {
  resource_arn = aws_appsync_graphql_api.backend_api.arn
  web_acl_arn  = aws_wafv2_web_acl.api_waf.arn
}

# Data sources, functions & resolvers
resource "aws_appsync_datasource" "none_ds" {
  api_id           = aws_appsync_graphql_api.backend_api.id
  name             = "NoneDs"
  type             = "NONE"
}

resource "aws_appsync_function" "function" {
  api_id      = aws_appsync_graphql_api.backend_api.id
  data_source = aws_appsync_datasource.none_ds.name
  name        = "testFunction"
  code        = file("${local.appsync_dir}/functions/test-function.js")

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  depends_on = [aws_appsync_datasource.none_ds]
}

resource "aws_appsync_resolver" "filters_resolver" {
  type   = "Query"
  api_id = aws_appsync_graphql_api.backend_api.id
  field  = "ping"
  kind   = "PIPELINE"
  code   = local.pipeline_resolver_code

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  pipeline_config {
    functions = [
      aws_appsync_function.function.function_id,
    ]
  }
}

resource "aws_appsync_resolver" "add_user_resolver" {
  type   = "Mutation"
  api_id = aws_appsync_graphql_api.backend_api.id
  field  = "newUser"
  kind   = "PIPELINE"
  code   = local.pipeline_resolver_code

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  pipeline_config {
    functions = [
      aws_appsync_function.function.function_id,
    ]
  }
}
