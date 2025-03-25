# Packer-Terraform
Project: AWS Infrastructure with Packer & Terraform

1. This project sets up:

- A custom Amazon Linux 2 AMI with Docker pre-installed (via Packer)
- A VPC with one public and one private subnet (via Terraform)
- A Bastion host in the public subnet
- 6 EC2 instances in the private subnet (using the custom AMI)

2. Prerequisites

- AWS credentials configured (via aws configure)
- Packer installed: https://developer.hashicorp.com/packer/install
- Terraform installed: https://developer.hashicorp.com/terraform/install
- A valid EC2 Key Pair created in your AWS account

3. Setup Instructions
- Clone the repository
  git clone <your-repo-url>
  cd Packer-Terraform
- Make setup script executable
  chmod +x setupscript.sh
- Set environment variables
  Replace with your actual key name and path (ensure the key pair exists in AWS):
  export SSH_KEY_NAME="packer-terraform"
  export SSH_KEY_PATH="/Users/1998p1/Downloads/packer-terraform.pem"
- Run the setup script
  This will:
  Build the AMI using Packer
  Provision infrastructure using Terraform
  ./setupscript.sh

4. Verifying the Setup
- SSH into the Bastion Host
  chmod 400 $SSH_KEY_PATH
  eval $(ssh-agent)
  ssh-add $SSH_KEY_PATH
  ssh -A ec2-user@<bastion-public-ip>
  Replace <bastion-public-ip> with the value printed from the terraform apply output.

- From the Bastion Host, SSH into a private EC2 instance
  ssh ec2-user@<private-ec2-ip>
- Then verify:
  cat /etc/os-release          # Should show Amazon Linux 2
  docker --version             # Docker should be installed
  sudo systemctl status docker # Docker should be running
  ping google.com              # Internet access via NAT

5. Cleanup
- To destroy all resources:
  cd terraform
  export TF_VAR_my_ip="$(curl -s https://checkip.amazonaws.com)/32"
  export TF_VAR_ssh_keypair_name=$SSH_KEY_NAME
  terraform destroy

