
variable "region" {
  type        = string
  description = "AWS Region. eg eu-west-1"
  default     = "eu-west-1"
}

variable "project" {
  type        = string
  description = "Project Name used to prefix resources."
  default     = "cloudfront-reverse-proxy"
}

variable "env" {
  description = "Environment name E.g. dev, int, prod"
  type        = string
  default     = "dev"
}