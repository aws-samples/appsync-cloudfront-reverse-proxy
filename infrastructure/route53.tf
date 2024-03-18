
resource "aws_route53_record" "upsert_domain_record" {
  zone_id = local.hosted_zone_id
  name    = local.hosted_zone
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.api_proxy.domain_name
    zone_id                = aws_cloudfront_distribution.api_proxy.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "upsert_domain_record_ip6" {
  zone_id = local.hosted_zone_id
  name    = local.hosted_zone
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.api_proxy.domain_name
    zone_id                = aws_cloudfront_distribution.api_proxy.hosted_zone_id
    evaluate_target_health = true
  }
}
# Uncomment to enable custom domain.
# resource "aws_route53_record" "certificate_cname_record" {
#   for_each = {
#     for dvo in aws_acm_certificate.backend_api_cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = local.hosted_zone_id
# }