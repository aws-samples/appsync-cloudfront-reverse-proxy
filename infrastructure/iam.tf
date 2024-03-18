resource "aws_iam_role" "api_logs_role" {
  name               = "api-logs-role-${var.region}-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.api_assume_role_policy.json
}
