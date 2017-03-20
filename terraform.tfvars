aws_region = "us-east-1"
vpc_cidr = "172.18.0.0/16"
net_public_count = "2"
net_private_count = "2"
efs_mt_count = "2"
postgres_instance = "db.t2.micro"
postgres_gitlab_dbname = "gitlabhq_production"
postgres_gitlab_user = "git"
elasticache_type = "cache.t2.micro"
elasticache_parameter_group = "default.redis3.2"
seed_instance_type = "t2.small"
gitlab_instance_type = "t2.small"
seed_ami = "ami-f4cc1de2"
ssl_certificate_name = "gitlab-certificate"
elb_healthy = "2"
elb_unhealthy = "3"
elb_timeout = "5"
elb_interval = "30"
ami_id = "H96CtUhVz0DVwkoC"
gitlab_instances_max = "2"
gitlab_instances_min = "2"
autoscaling_check_grace = "300"
autoscaling_check_type = "EC2"
autoscaling_capacity = "2"
