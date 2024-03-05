variable "vpc_id" {
 type = string
}

#variable "record_ips" {
#  type = map(
#     list(object(
#       {
#         ip = string
#         port = string
#       }
#     )
#    )
#  )
#}

variable "records" {}

variable "zone_name" {}
