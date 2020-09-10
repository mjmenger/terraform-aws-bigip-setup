output "vpc" {
  description = "AWS VPC ID for the created VPC"
  value       = module.vpc.vpc_id
}

output "bigip_mgmt_public_ips" {
  description = "Public IP addresses for the BIG-IP management interfaces"
  value       = module.bigip.mgmt_public_ips
}

output "bigip_mgmt_port" {
  description = "BIG-IP management port"
  value       = module.bigip.mgmt_port
}

output "bigip_password" {
  description = "BIG-IP management password"
  value       = random_password.password.result
}

output "jumphost_ip" {
  description = "ip address of jump host"
  value       = module.jumphost.public_ip
}

output "ec2_key_name" {
  description = "the key used to communication with ec2 instances"
  value       = var.ec2_key_name
}

output "ec2_key_file" {
  description = "private key to access VMs"
  value       = var.ec2_key_file
}

output "juiceshop_ip" {
  value = aws_eip.juiceshop[*].public_ip
}

output "grafana_ip" {
  value = aws_eip.grafana[*].public_ip
}