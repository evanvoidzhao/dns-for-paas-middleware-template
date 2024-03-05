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
  #ips = toset(flatten([
  #  for name, list in var.record_ips:[
  #    for k, i in list:  {
  #      ip = i.ip
  #      port = i.port
  #    }
  #  ]
  #]))
  records = toset(flatten([
    for name, list in var.records:[
      for k,v in list:  {
        ip = k
        port = v
        name = name
      }
    ]
  ]))
  ips_local = {for i in local.records: "${i.ip}_${i.port}" => i}
}

resource "random_id" "this" {
  byte_length = 8
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.ips_local
  alarm_name                = "dns_alarm_${each.value.ip}_${each.value.port}_${random_id.this.hex}"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = 2
  metric_name               = "HealthStatus"
  namespace                 = "IPPortHealth"
  period                    = 60
  statistic                 = "Minimum"
  threshold                 = 1
  insufficient_data_actions = []

  dimensions = {
    IP = each.value.ip
    Port = each.value.port
    Name = each.value.name
  }
}

data "aws_region" "current" {}

resource "aws_route53_health_check" "this" {
  for_each = aws_cloudwatch_metric_alarm.this 
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = each.value.alarm_name
  cloudwatch_alarm_region         = data.aws_region.current.name
  insufficient_data_health_status = "Unhealthy"
  tags = {
    Name = "dns_health_check_${local.ips_local[each.key].name}_${each.key}"
  }
}


