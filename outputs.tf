output "gitlab-elb" {
  value = "${aws_elb.gitlab-elb.dns_name}"
}
