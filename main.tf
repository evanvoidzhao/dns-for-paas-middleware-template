terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}


module "r53" {
  source = "./modules/r53"
  
  vpc_id = var.vpc_id
  route53_zone_name = var.zone_name
#  record_ips = var.record_ips
  records = var.records
  health_checks = module.cloudwatch.health_checks
#  depends_on = [
#    module.cloudwatch
#  ]
}

module "lambda" {
  source = "./modules/lambda"
}

module "eventbridge" {
  source = "./modules/eventbridge"
 
# record_ips = var.record_ips
  records = var.records  

  lambda_arn = module.lambda.lambda_arn
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
 
#  record_ips = var.record_ips
  records = var.records
}

#module "r53_health_check" {
#   source = "./modules/r53_health_check"
#   
#   alarm_names = module.cloudwatch.cloudwatch_alarms
#}


