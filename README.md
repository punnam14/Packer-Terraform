# Packer-Terraform
This project explains the process of setting up AWS Infrastructure with Packer & Terraform

## 1. This project sets up:

- A custom Amazon Linux 2 AMI with Docker pre-installed (via Packer)
- A VPC with one public and one private subnet (via Terraform)
- A Bastion host in the public subnet
- 6 EC2 instances in the private subnet (using the custom AMI)

## 2. Prerequisites

- AWS credentials configured (via aws configure)
- Packer installed: https://developer.hashicorp.com/packer/install
- Terraform installed: https://developer.hashicorp.com/terraform/install
- A valid EC2 Key Pair created in your AWS account

## 3. Setup Instructions
- Clone the repository  
  `git clone <repo-url>`  
  `cd Packer-Terraform`  
- Make setup script executable  
  `chmod +x setupscript.sh`  
- Set environment variables  
  Replace with your actual key name and path (ensure the key pair exists in AWS):  
  `export SSH_KEY_NAME="packer-terraform"`  
  `export SSH_KEY_PATH="/Users/1998p1/Downloads/packer-terraform.pem"`  
- Run the setup script  
  This will:  
  Build the AMI using Packer  
  Provision infrastructure using Terraform  
  `./setupscript.sh`  
  You should get an output like the one shown in the screenshot:
  
  ![Screenshot 2025-03-25 at 1 28 18 PM](https://github.com/user-attachments/assets/a38f43a8-d361-4416-baae-1b8145936c3f)

## 4. Verifying the Setup  
- SSH into the Bastion Host  
  `chmod 400 $SSH_KEY_PATH`  
  `eval $(ssh-agent)`  
  `ssh-add $SSH_KEY_PATH`  
  `ssh -A ec2-user@<bastion-public-ip>`  
  Replace <bastion-public-ip> with the value printed from the terraform apply output.

- From the Bastion Host, SSH into a private EC2 instance  
  `ssh ec2-user@<private-ec2-ip>`  
- Then verify:  
  `cat /etc/os-release`          # Should show Amazon Linux 2  
  `docker --version`             # Docker should be installed  
  `sudo systemctl status docker` # Docker should be running  
  `ping google.com`              # Internet access via NAT

  ![Screenshot 2025-03-25 at 1 21 16 PM](https://github.com/user-attachments/assets/cbac494d-8673-424b-ac3d-df1d5a3ce10e)


## 5. Cleanup
- To destroy all resources:  
  `cd terraform`  
  `export TF_VAR_my_ip="$(curl -s https://checkip.amazonaws.com)/32"`  
  `export TF_VAR_ssh_keypair_name=$SSH_KEY_NAME`  
  `terraform destroy`  
  
## 6. AWS Checks

- AMI Creation  
  
  ![Screenshot 2025-03-25 at 1 24 10 PM](https://github.com/user-attachments/assets/079aed02-041d-4330-87e4-6551eac012d8)

- VPC  
  
  ![Screenshot 2025-03-25 at 1 22 05 PM](https://github.com/user-attachments/assets/e9bf94da-1d99-40d1-80d3-10030e43e012)

- 2 Security groups created  
  
  ![Screenshot 2025-03-25 at 1 26 28 PM](https://github.com/user-attachments/assets/0198baa9-6118-4679-86cf-364627da6847)
  ![Screenshot 2025-03-25 at 1 27 16 PM](https://github.com/user-attachments/assets/7b642468-c8ce-4e8c-99cc-bde0d9cc7eba)

- 7 EC2 Instances  
  
  ![Screenshot 2025-03-25 at 1 22 51 PM](https://github.com/user-attachments/assets/adc65b72-f8dc-45d3-bd58-187b01f7bd8e)

- Private EC2 Instance uses the created AMI  
  
  ![Screenshot 2025-03-25 at 1 20 48 PM](https://github.com/user-attachments/assets/57a5aa61-b704-4368-93a1-390acab288ad)
