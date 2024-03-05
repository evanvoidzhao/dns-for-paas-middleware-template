terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

locals {
#  ips = toset(flatten([
#    for name, list in var.record_ips:[
#      for k, i in list:  {
#        ip = i.ip
#        port = i.port
#        name = name
#      }        
#    ] 
#  ]))

  records = toset(flatten([
    for name, list in var.records:[
      for i, v  in list:  {
        ip = i
        port = v
        name = name
      }
    ]
  ]))
 
  ips_local = {for i in local.records: "${i.name}_${i.ip}" => i}

}

data "aws_route53_zone" "selected" {
  name         = var.route53_zone_name
  private_zone = true
}

#resource "aws_route53_zone" "private" {
#  name = var.route53_zone_name
#
# vpc {
#    vpc_id = var.vpc_id
#  }
#}

#data "aws_region" "current" {}

resource "aws_route53_record" "this" {
  for_each  = local.ips_local
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = each.value.name
  type    = "A"
  ttl     = 60
  set_identifier = each.value.ip
  multivalue_answer_routing_policy =  true
  records        = [each.value.ip]

  health_check_id = var.health_checks["${each.value.ip}_${each.value.port}"].id
}

#resource "aws_route53_health_check" "this" {

#  for_each = local.alarms
#  type                            = "CLOUDWATCH_METRIC"
#  cloudwatch_alarm_name           = each.value
#  cloudwatch_alarm_region         = data.aws_region.current.name
#  insufficient_data_health_status = "Unhealthy"
#}
