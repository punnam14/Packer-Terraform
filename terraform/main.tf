terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "external" "amazon_ami" {
  program = ["bash", "-c", "echo '{\"ami_id\":\"'$(grep 'amazon-linux' ../packer/ami_id.txt | awk '{print $2}')'\"}'"]
}

data "external" "ubuntu_ami" {
  program = ["bash", "-c", "echo '{\"ami_id\":\"'$(grep 'ubuntu-docker' ../packer/ami_id.txt | awk '{print $2}')'\"}'"]
}


# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
}

# Private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}a"
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}

# NAT Gateway with Elastic IP
resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  depends_on = [aws_internet_gateway.gw]
}

# Public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from specific IP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = data.external.amazon_ami.result.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = var.ssh_keypair_name
}

# Security Group for Private EC2 Instances
resource "aws_security_group" "private_ec2_sg" {
  name        = "private-ec2-sg"
  description = "Allow SSH from bastion only"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Private EC2 Instances
resource "aws_instance" "amazon_instances" {
  count                  = 3
  ami                    = data.external.amazon_ami.result.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]
  key_name               = var.ssh_keypair_name
  tags = {
    OS = "amazon"
  }
}

resource "aws_instance" "ubuntu_instances" {
  count                  = 3
  ami                    = data.external.ubuntu_ami.result.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_ec2_sg.id]
  key_name               = var.ssh_keypair_name
  tags = {
    OS = "ubuntu"
  }
}
 