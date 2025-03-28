#!/bin/bash

set -e

# Verify variables
if [ -z "$SSH_KEY_PATH" ]; then
  echo "Please export SSH_KEY_PATH"
  exit 1
fi

# Read Bastion IP & Private IPs
cd terraform
BASTION_IP=$(terraform output -raw bastion_public_ip)
AMAZON_IPS=$(terraform output -json amazon_private_ips | jq -r '.[]')
UBUNTU_IPS=$(terraform output -json ubuntu_private_ips | jq -r '.[]')
cd ..

# Go to ansible folder
cd ansible

# Create dynamic inventory
ANSIBLE_KEY_FILE=$(basename $SSH_KEY_PATH)

cat <<EOF > inventory.ini
[amazon]
$(for ip in $AMAZON_IPS; do echo "$ip ansible_user=ec2-user"; done)

[ubuntu]
$(for ip in $UBUNTU_IPS; do echo "$ip ansible_user=ubuntu"; done)

[all:vars]
ansible_ssh_private_key_file=/home/ec2-user/${ANSIBLE_KEY_FILE}
EOF

echo "✅ Dynamic inventory created."

# Copy key & ansible files to Bastion
scp -o StrictHostKeyChecking=no -i $SSH_KEY_PATH \
  $SSH_KEY_PATH inventory.ini playbook.yml ansible.cfg \
  ec2-user@${BASTION_IP}:/home/ec2-user/ansible/

# SSH into Bastion and run playbook
ssh -i $SSH_KEY_PATH ec2-user@${BASTION_IP} <<EOF
  mv /home/ec2-user/ansible/${ANSIBLE_KEY_FILE} /home/ec2-user/
  chmod 400 /home/ec2-user/${ANSIBLE_KEY_FILE}
  sudo amazon-linux-extras enable ansible2
  sudo yum install -y ansible
  cd ansible
  ansible-playbook playbook.yml
EOF

echo "✅ Ansible Playbook executed successfully."