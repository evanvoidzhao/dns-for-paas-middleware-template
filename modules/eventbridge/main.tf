terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_dns_eventbridge" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "lambda_health_check_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "arn:aws:lambda:*:*:function:dns_health_check*:*",
                "arn:aws:lambda:*:*:function:dns_health_check*"
            ]
        }
      ]
    })
  } 
}

locals {
#  ips = toset(flatten([
#    for name, list in var.record_ips:[
#      for k, i in list:  {
#        ip = i.ip
#        port = i.port
#      }
#    ]
#  ]))
 
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

resource "aws_scheduler_schedule" "this" {
  for_each = local.ips_local
  name = "dns_health_check_${each.value.ip}_${each.value.port}_${random_id.this.hex}"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 minutes)"

  target {
    arn      = var.lambda_arn
    role_arn = aws_iam_role.iam_for_dns_eventbridge.arn

    input = jsonencode({
      IP_ADDR = each.value.ip
      PORT    = each.value.port
      NAME    = each.value.name
    })
  }
}
