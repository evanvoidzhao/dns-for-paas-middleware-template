output "cloudwatch_alarms" {
  value = [ for k, v in local.ips_local: "dns_alarm_${v.ip}_${v.port}_${random_id.this.hex}" ]
}
output "health_checks" {
  value = aws_route53_health_check.this 
}
