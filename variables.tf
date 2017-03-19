variable "access_key" {}
variable "secret_key" {}
variable "aws_region" {}
variable "vpc_cidr" {}
variable "net_public_count" {}
variable "net_public" {
  default = {
    "0" = "172.18.101.0/24"
    "1" = "172.18.102.0/24"
  }
}
variable "net_private_count" {}
variable "net_private" {
  default = {
    "0" = "172.18.1.0/24"
    "1" = "172.18.2.0/24"
  }
}
