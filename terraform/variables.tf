variable "aws_region" {
  default = "us-east-1"
}

variable "ssh_keypair_name" {
  description = "AWS Key Pair Name"
}

variable "my_ip" {
  description = "Your IP to restrict SSH access (example: 1.2.3.4/32)"
}
