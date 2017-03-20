#!/bin/bash
###########################################################
#
# This script checks environment and defines random values
# for password, key and certs
#
###########################################################

WORKDIR=./work

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

# Check if sshkey is included
if [ -z ${TF_VAR_ssh_key_name} ]; then
  echo "Creating ssh key..."
  ssh-keygen -q -b 2048 -N "" -f  "${WORKDIR}/gitlab-key.pem"
  export TF_VAR_ssh_key_name="gitlab_key"
  export TF_VAR_ssh_key_path="${WORKDIR}/gitlab-key.pem.pub"
  export TF_VAR_ssh_key_private_path="${WORKDIR}/gitlab-key.pem"
fi

# Create PostgreSQL Password

