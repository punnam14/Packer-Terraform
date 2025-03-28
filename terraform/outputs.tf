output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "amazon_private_ips" {
  value = aws_instance.amazon_instances[*].private_ip
}

output "ubuntu_private_ips" {
  value = aws_instance.ubuntu_instances[*].private_ip
}
