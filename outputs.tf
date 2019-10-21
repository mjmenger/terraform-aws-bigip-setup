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

output "nginx_ips" {
  description = "Internal IP addresses of the demo app servers"
  value       = module.nginx-demo-app.private_ips
}

output "jumphost_ip" {
  description = "ip address of jump host"
  value       = module.jumphost.public_ip
}
