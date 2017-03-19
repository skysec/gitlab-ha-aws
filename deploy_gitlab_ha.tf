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
    Name = "net-public-0${count.index}"
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
    Name = "net-private-0${count.index}"
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
