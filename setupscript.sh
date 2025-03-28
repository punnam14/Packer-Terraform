#!/bin/bash

# Fail fast on any errors
set -e

# Verify required environment variables are set
if [ -z "$SSH_KEY_NAME" ] || [ -z "$SSH_KEY_PATH" ]; then
  echo "Please set SSH_KEY_NAME and SSH_KEY_PATH environment variables."
  exit 1
fi

# Navigate to Packer directory and build AMI
echo "🚀 Starting Packer build..."
cd packer

packer init ami.pkr.hcl

packer validate \
  -var "ssh_keypair_name=${SSH_KEY_NAME}" \
  -var "ssh_private_key_file=${SSH_KEY_PATH}" \
  ami.pkr.hcl

# Build AMI and capture AMI ID dynamically
packer build \
  -var "ssh_keypair_name=${SSH_KEY_NAME}" \
  -var "ssh_private_key_file=${SSH_KEY_PATH}" \
  ami.pkr.hcl | tee packer_output.txt

# Extract AMI ID
AMAZON_AMI_ID=$(grep 'amazon-ebs.docker_ami: AMIs were created:' packer_output.txt -A1 | grep 'us-east-1:' | awk '{print $2}')
UBUNTU_AMI_ID=$(grep 'amazon-ebs.ubuntu_docker_ami: AMIs were created:' packer_output.txt -A1 | grep 'us-east-1:' | awk '{print $2}')

# Save to file
echo "amazon-linux ${AMAZON_AMI_ID}" > ami_id.txt
echo "ubuntu-docker ${UBUNTU_AMI_ID}" >> ami_id.txt

rm packer_output.txt

echo "✅ Amazon Linux AMI ID: ${AMAZON_AMI_ID}"
echo "✅ Ubuntu AMI ID: ${UBUNTU_AMI_ID}"

# Navigate to Terraform directory
cd ../terraform

# Dynamically retrieve user's current public IP
export TF_VAR_my_ip="$(curl -s https://checkip.amazonaws.com)/32"
export TF_VAR_ssh_keypair_name="${SSH_KEY_NAME}"

# Terraform setup
terraform init
terraform apply -auto-approve
rm ../packer/ami_id.txt

echo "✅ Terraform setup complete!"

# Run Ansible script
echo "🚀 Starting Ansible Playbook Execution..."
chmod +x run-ansible.sh
./run-ansible.sh