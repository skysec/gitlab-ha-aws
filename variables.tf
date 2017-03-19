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
variable "efs_mt_count" {}
variable "postgres_instance" {}
variable "postgres_gitlab_dbname" {}
variable "postgres_gitlab_user" {}
variable "postgres_gitlab_pass" {}
variable "elasticache_type" {}
variable "elasticache_parameter_group" {}
variable "ssh_key_name" {}
variable "ssh_key_path" {}
variable "ssh_key_private_path" {}
variable "seed_instance_type" {}
variable "seed_ami" {}
variable "ssl_certificate_name" {}
variable "ssl_certificate_public" {}
variable "ssl_certificate_private" {}
