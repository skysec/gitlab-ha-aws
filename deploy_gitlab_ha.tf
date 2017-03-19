#######
#
# Create AWS Resources and deploy gitlab in HA
#
######

# Use AWS as provider

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.aws_region}"
}

# Declare data source AZ

data "aws_availability_zones" "available" {}

# Create a new VPC, the CIDR is specified as a var

resource "aws_vpc" "vpc-gitlab" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags {
    Name = "gitlab-vpc"
    User = "skysec"
  }
}

# Let's create an Internet gateway for the new VPC

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc-gitlab.id}"
}

# Default Routing Table

resource "aws_default_route_table" "rt-gitlab-private" {
  default_route_table_id = "${aws_vpc.vpc-gitlab.default_route_table_id}"
  tags {
    Name = "rt-gitlab-private",
    User = "skysec"
  }
}

# Public routing Table

resource "aws_route_table" "rt-gitlab-public" {
  vpc_id = "${aws_vpc.vpc-gitlab.id}"
  route {
        cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_internet_gateway.igw.id}"
	}
  tags {
	  Name = "rt-gitlab-public"
    user = "skysec"
  }
}

# Create subnets:
# Two Public and Two private subnet, each pair public/private
# on a specific AZ, in order to match the ELB with public subnets
# and EC2 instances with private subnets
# First Public subnets...

resource "aws_subnet" "net-gitlab-public" {
  count = "${var.net_public_count}"
  vpc_id = "${aws_vpc.vpc-gitlab.id}"
  cidr_block = "${lookup(var.net_public, count.index)}"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  tags {
    Name = "gitlab-net-public-0${count.index}"
    User = "skysec"
  }
}

# Now Private subnets
resource "aws_subnet" "net-gitlab-private" {
  count = "${var.net_private_count}"
  vpc_id = "${aws_vpc.vpc-gitlab.id}"
  cidr_block = "${lookup(var.net_private, count.index)}"
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  tags {
    Name = "gitlab-net-private-0${count.index}"
    User = "skysec"
  }
}

# Map subnet and routing tables
resource "aws_route_table_association" "rt_public_subnet" {
  count = "${var.net_public_count}"
  subnet_id = "${element(aws_subnet.net-gitlab-public.*.id,count.index)}"
  route_table_id = "${aws_route_table.rt-gitlab-public.id}"
}

resource "aws_route_table_association" "rt_private_subnet" {
  count = "${var.net_public_count}"
  subnet_id = "${element(aws_subnet.net-gitlab-private.*.id,count.index)}"
  route_table_id = "${aws_default_route_table.rt-gitlab-private.id}"
}

# Create an RDS subnet group

resource "aws_db_subnet_group" "db_net_group" {
  name = "db-net-group"
  subnet_ids = ["${aws_subnet.net-gitlab-private.*.id}"]

  tags {
    Name = "gitlab_db_net_group"
    User = "skysec"
  }
}

# Create Elasticache Subnet group

resource "aws_elasticache_subnet_group" "redis_net_group" {
  name = "redis-net-group"
  subnet_ids = ["${aws_subnet.net-gitlab-private.*.id}"]

}

# Security groups

resource "aws_security_group" "sg_gitlab_public" {
  name = "sg_gitlab_public"
  description = "SSH, HTTP and HTTPS Access for ELB and Seed"
  vpc_id = "${aws_vpc.vpc-gitlab.id}"
  # Secure shell
  ingress {
    from_port 	= 22
    to_port 	= 22
    protocol 	= "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTP
  ingress {
    from_port 	= 80
    to_port 	= 80
    protocol 	= "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }
  # HTTPS
  ingress {
    from_port 	= 443
    to_port 	= 443
    protocol 	= "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }
  #Internet Access
  egress {
    from_port	= 0
    to_port 	= 0
    protocol	= "-1"
    cidr_blocks	= ["0.0.0.0/0"]
  }

  tags {
    Name = "gitlab-sg-public"
    User = "skysec"
  }
}

resource "aws_security_group" "sg_gitlab_private" {
  name        = "sg_gitlab_private"
  description = "Internal Instances"
  vpc_id      = "${aws_vpc.vpc-gitlab.id}"
  # SSH: Internal only
  ingress {
    from_port 	= 0
    to_port 	= 0
    protocol 	= "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  #Internet Access
  egress {
    from_port	= 0
    to_port 	= 0
    protocol	= "-1"
    cidr_blocks	= ["0.0.0.0/0"]
  }

  tags {
    Name = "gitlab-sg-private"
    User = "skysec"
  }
}

resource "aws_security_group" "sg_gitlab_postgresql" {
  name= "sg_gitlab_postgresql"
  description = "PostgreSQL Security Group"
  vpc_id      = "${aws_vpc.vpc-gitlab.id}"
  # PostgreSQL access to internal instances and seed
  ingress {
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = ["${aws_security_group.sg_gitlab_public.id}", "${aws_security_group.sg_gitlab_private.id}"]
  }

  tags {
    Name = "sg_gitlab_postgresql"
    User = "skysec"
  }
}

resource "aws_security_group" "sg_gitlab_redis" {
  name= "sg_gitlab_redis"
  description = "Redis Security Group"
  vpc_id      = "${aws_vpc.vpc-gitlab.id}"
  # PostgreSQL access to internal instances and seed
  ingress {
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    security_groups  = ["${aws_security_group.sg_gitlab_public.id}", "${aws_security_group.sg_gitlab_private.id}"]
  }

  tags {
    Name = "sg_gitlab_redis"
    User = "skysec"
  }
}

# EFS
resource "aws_efs_file_system" "gitlab_efs" {
  creation_token = "gitlab_efs_001"

  tags {
    Name = "gitlab_efs"
    User = "skysec"
  }
}

resource "aws_efs_mount_target" "gitlab_efs_mt" {
  count = "${var.efs_mt_count}"
  file_system_id = "${aws_efs_file_system.gitlab_efs.id}"
  subnet_id      = "${element(aws_subnet.net-gitlab-private.*.id,count.index)}"
  security_groups = ["${aws_security_group.sg_gitlab_public.id}", "${aws_security_group.sg_gitlab_private.id}"]
}

# RDS - PostgreSQL
resource "aws_db_instance" "gitlab-postgres" {
  allocated_storage	= 10
  engine		= "postgres"
  engine_version	= "9.5.4"
  instance_class	= "${var.postgres_instance}"
  name			= "${var.postgres_gitlab_dbname}"
  username		= "${var.postgres_gitlab_user}"
  password		= "${var.postgres_gitlab_pass}"
  db_subnet_group_name  = "${aws_db_subnet_group.db_net_group.name}"
  vpc_security_group_ids = ["${aws_security_group.sg_gitlab_postgresql.id}"]
  skip_final_snapshot = true
  tags {
    Name = "gitlab-postgres"
    User = "skysec"
  }
}

# Elasticache redis
resource "aws_elasticache_cluster" "gitlab-redis" {
  cluster_id           = "gitlab-redis-001"
  engine               = "redis"
  node_type            = "${var.elasticache_type}"
  port                 = 6379
  num_cache_nodes      = 1
  parameter_group_name = "${var.elasticache_parameter_group}"
  subnet_group_name    = "${aws_elasticache_subnet_group.redis_net_group.name}"
  security_group_ids   = ["${aws_security_group.sg_gitlab_redis.id}"]
  tags {
    Name = "gitlab-redis"
    User = "skysec"
  }
}

# SSH key pair
resource "aws_key_pair" "gitlab-keypair" {
  key_name  ="${var.ssh_key_name}"
  public_key = "${file(var.ssh_key_path)}"
}

# Create the EC2 seed instance
# This instance will be used as a source for an ami
# to be deployed with autoscaling
resource "aws_instance" "gitlab-seed" {
  instance_type = "${var.seed_instance_type}"
  ami = "${var.seed_ami}"
  key_name = "${aws_key_pair.gitlab-keypair.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_gitlab_public.id}"]
  subnet_id = "${aws_subnet.net-gitlab-public.0.id}"
  tags {
    Name = "gitlab-seed"
    User = "skysec"
  }

  provisioner "local-exec" {
    command = <<SCRIPT
cat <<EOF > work/vars
[public ip]
${aws_instance.gitlab-seed.public_ip}
[rds_endpoint]
${aws_db_instance.gitlab-postgres.endpoint}
[redis_endpoint]
${aws_elasticache_cluster.gitlab-redis.cache_nodes.0.address}
[efs_mountpoint]
${aws_efs_file_system.gitlab_efs.id}.efs.${var.aws_region}.amazonaws.com
[availability_zone]
${aws_instance.gitlab-seed.availability_zone}
EOF
SCRIPT
  }
  provisioner "local-exec" {
    command = <<SCRIPT
INSTANCE_IP=${aws_instance.gitlab-seed.public_ip} \
RDS_ENDPOINT=${aws_db_instance.gitlab-postgres.endpoint} \
RDS_PASS=${var.postgres_gitlab_pass} \
REDIS_ENDPOINT=${aws_elasticache_cluster.gitlab-redis.cache_nodes.0.address} \
KEYPAIR=${var.ssh_key_path} \
EFS="${aws_efs_file_system.gitlab_efs.id}.efs.${var.aws_region}.amazonaws.com" \
./configure_instances.sh
SCRIPT
  }
}

#Upload gitlab SSL Certificate

resource "aws_iam_server_certificate" "gitlab-ssl-cert" {
  name             = "${var.ssl_certificate_name}"
  certificate_body = "${file(var.ssl_certificate_public)}"
  private_key      = "${file(var.ssl_certificate_private)}"
}
