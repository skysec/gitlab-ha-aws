#!/bin/bash
###########################################################
#
# This script checks environment and defines random values
# for password, key and certs
#
###########################################################

WORKDIR=./work

if [ ! -d "${WORKDIR}" ]; then
   mkdir "${WORKDIR}"
fi

# Check if a given program is in PATH
check_program () {
  
if [ ! $(which $1) ]; then
   echo "$1 not found in PATH"
   exit 1
fi
}

# Check if terraform, ansible and openssl are in PATH
for I in terraform ansible openssl 
do
  check_program "${I}"
done

# Check for AWS Access Keys
if [ -z ${AWS_ACCESS_KEY_ID} ] || [ -z ${AWS_ACCESS_KEY_ID} ]; then
  echo "AWS Access keys are not defined"
  exit 1
fi

# export vars needed by terraform
export TF_VAR_access_key=${AWS_ACCESS_KEY_ID}
export TF_VAR_secret_key=${AWS_SECRET_ACCESS_KEY}

# Check if sshkey is included
if [ -z ${TF_VAR_ssh_key_name} ]; then
  echo "Creating ssh key..."
  ssh-keygen -q -b 2048 -N "" -f  "${WORKDIR}/gitlab-key.pem"
  export TF_VAR_ssh_key_name="gitlab_key"
  export TF_VAR_ssh_key_path="${WORKDIR}/gitlab-key.pem.pub"
  export TF_VAR_ssh_key_private_path="${WORKDIR}/gitlab-key.pem"
fi

# Create PostgreSQL Password
export TF_VAR_postgres_gitlab_pass=$(openssl rand -base64 20 | sed 's/\///g')

# Create self-signed certificate
openssl req -x509 -newkey rsa:2048 -keyout "${WORKDIR}/key.pem" -out "${WORKDIR}/cert.pem" -days 90 -nodes -subj "/C=CA/ST=ON/O=Secret/CN=gitlab.example.com" 

# Certificate Vars
export TF_VAR_ssl_certificate_public="${WORKDIR}/cert.pem"
export TF_VAR_ssl_certificate_private="${WORKDIR}/key.pem"

# terraform plan
terraform plan

if [ $? -ne 0 ]; then
   echo "Ooops! something is wrong"
   exit 1
fi

# terraform apply
terraform apply
