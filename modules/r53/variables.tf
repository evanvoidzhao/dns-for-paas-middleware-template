variable "vpc_id" {
  type = string
}

variable "route53_zone_name" {
  type = string
  default = "example.com"
}

#variable "record_ips" {}
variable "records" {}

variable "health_checks" {}
