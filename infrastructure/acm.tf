resource "aws_acm_certificate" "backend_api_cert" {
  provider          = aws.us_east_1
  domain_name       = local.api_domain
  validation_method = "DNS"
  tags              = local.default_tags
  lifecycle {
    create_before_destroy = true
  }
}
# Uncomment to enable custom domain.
# resource "aws_acm_certificate_validation" "backend_api_cert_validation" {
#   provider                = aws.us_east_1
#   certificate_arn         = aws_acm_certificate.backend_api_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.certificate_cname_record : record.fqdn]
# }