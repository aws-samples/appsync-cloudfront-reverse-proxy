locals {
      hosted_zone           = data.aws_route53_zone.hosted_zone.name
      hosted_zone_id        =  data.aws_route53_zone.hosted_zone.zone_id
      api_domain            = "api.${local.hosted_zone}"
      appsync_dir           = "../api"
      default_tags          = {
        PROJ                = var.project
        ENV                 = var.env
        MODULE              = "project"
        "COST TAG 1"        = "DEVELOPMENT"
  }
  waf_identity_header_name = "X-Origin-Verify"
}