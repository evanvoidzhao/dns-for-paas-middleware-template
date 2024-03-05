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
  alarm_names = toset(var.alarm_names)
}


data "aws_region" "current" {}


resource "aws_route53_health_check" "this" {
  for_each = local.alarm_names
  type                            = "CLOUDWATCH_METRIC"
  cloudwatch_alarm_name           = each.value
  cloudwatch_alarm_region         = data.aws_region.current.name
  insufficient_data_health_status = "Unhealthy"
}
