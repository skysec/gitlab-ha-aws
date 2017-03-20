#!/bin/bash
###########################################################
#
# This script checks environment and destroy all
# resources
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

# Define ssh values  to avoid been prompted by terraform
export TF_VAR_ssh_key_name="gitlab_key"
export TF_VAR_ssh_key_path="${WORKDIR}/gitlab-key.pem.pub"
export TF_VAR_ssh_key_private_path="${WORKDIR}/gitlab-key.pem"

# Define dummy password to avoid been prompted by terraform
export TF_VAR_postgres_gitlab_pass="somevalue"

# Define SSL cert values to avoid been prompted by terraform
export TF_VAR_ssl_certificate_public="${WORKDIR}/cert.pem"
export TF_VAR_ssl_certificate_private="${WORKDIR}/key.pem"

# terraform destroy
terraform destroy --force

