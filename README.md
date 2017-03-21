# GitLab HA AWS

GitLab comes handy when we need an internal repository for our projects. But it
becomes an important service when most of the projects start to depend on the
availability of the service.

Checking the documentation, there is a HA option, using NFS, and separating
the different services: PostgreSQL and REDIS.

This is a set of scripts that allow a setup of gitlab HA in AWS with a single
command: "init.sh"

# Dependencies

In order to execute the scripts, the following is needed:

* terraform (0.8 or 0.9)
* ansible (2.x)
* openssl

Any Linux distro is an excellent choice to run the script.

Also, AWS credentials are needed with enough privileges to create the resources.

# How it works

Define the AWS credentials as environment vars: AWS_ACCESS_KEY_ID and
AWS_SECRET_ACCESS_KEY, and execute ./init.sh.

Once the infrastructure has been created, the script outputs the dns name of
the Elastic Load Balancer (ELB). The gitlab-ha service should be available at:

https://<ELB_dns_name>

Give 3 to 5 minutes for the application to become available.

In order to destroy the resources, run "./terminate.sh", and it'll terminate
all resources. In some cases, terraform fails to delete the Internet Gateway 
associated to the VPC, in this case, just re-run "./terminate.sh" to continue
the deletion process.

# Internals

The script works as follows:

* Creates a ssh key pair.
* Creates a self signed certificate.
* Creates a random password for posgresSQL access.
* Creates a new VPC.
* Creates two public (ELB and Seed) and two private subnets. Each pair public /
private match an AZ.
* Creates three security groups: public (ELB and seed instance), private
(internal instances) and postgres (RDS).
* Creates a RDS (PostgreSQL engine).
* Creates an elasticache service (Redis).
* Creates an EFS service with two mount points (one per private subnet).
* Creates an EC2 instance, that will work as a seed for the launch configuration.
* The seed instance is configured using ansible and gitlab omnibus.
* An Elastic Load Balancer is created with the self signed certificate.
* An AMI is created from the seed instance.
* A launch configuration is created using the seed instance.
* An Autoscaling group is created based on the previously created launch
configuration.

# AWS Resources:

* VPC
* subnets
* Security Groups
* RDS (PostgreSQL)
* Elasticache (redis)
* EFS
* EC2
* ELB
* Launch configuration
* Autoscaling
