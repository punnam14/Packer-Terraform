packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.3"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ssh_keypair_name" {
  type = string
}

variable "ssh_private_key_file" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

source "amazon-ebs" "docker_ami" {
  region = var.aws_region

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  instance_type        = var.instance_type
  ssh_username         = "ec2-user"
  ami_name             = "amazon-linux-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  ami_description      = "Amazon Linux 2 with Docker pre-installed"
  ssh_keypair_name     = var.ssh_keypair_name
  ssh_private_key_file = var.ssh_private_key_file
}

build {
  sources = ["source.amazon-ebs.docker_ami"]

  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ec2-user"
    ]
  }
}
