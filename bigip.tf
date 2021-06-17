
#
# Create random password for BIG-IP
#
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

#
# Create Secret Store and Store BIG-IP Password
#
resource "aws_secretsmanager_secret" "bigip" {
  name = format("%s-bigip-secret-%s", var.prefix, random_id.id.hex)
}
resource "aws_secretsmanager_secret_version" "bigip-pwd" {
  secret_id     = aws_secretsmanager_secret.bigip.id
  secret_string = random_password.password.result
}


#
# Create the BIG-IP appliances
#
module "bigip" {
  source  = "f5devcentral/bigip/aws"
  version = "0.1.4.1"

  prefix = format(
    "%s-bigip-3-nic_with_new_vpc-%s",
    var.prefix,
    random_id.id.hex
  )
  aws_secretmanager_secret_id = aws_secretsmanager_secret.bigip.id
  application_endpoint_count  = 3
  f5_ami_search_name          = "F5 BIGIP-15.* PAYG-Best 200Mbps*"
  f5_instance_count           = length(var.azs)
  ec2_key_name                = var.ec2_key_name
  ec2_instance_type           = var.ec2_bigip_type
  DO_URL                      = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.14.0/f5-declarative-onboarding-1.14.0-1.noarch.rpm"
  AS3_URL                     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.22.1/f5-appsvcs-3.22.1-1.noarch.rpm"
  TS_URL                      = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.14.0/f5-telemetry-1.14.0-2.noarch.rpm"

  mgmt_subnet_security_group_ids = [
    module.bigip_mgmt_sg.this_security_group_id
  ]


  public_subnet_security_group_ids = [
    module.bigip_sg.this_security_group_id,
    module.bigip_mgmt_sg.this_security_group_id
  ]

  private_subnet_security_group_ids = [
    module.bigip_sg.this_security_group_id,
    module.bigip_mgmt_sg.this_security_group_id
  ]


  vpc_public_subnet_ids  = module.vpc.public_subnets
  vpc_private_subnet_ids = module.vpc.private_subnets
  vpc_mgmt_subnet_ids    = module.vpc.database_subnets
}


#
# Create a security group for BIG-IP
#
module "bigip_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"

  name        = format("%s-bigip-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP Demo"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [var.allowed_app_cidr]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.bigip_sg.this_security_group_id
    }
  ]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}

#
# Create a security group for BIG-IP Management
#
module "bigip_mgmt_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "3.18.0"
  name        = format("%s-bigip-mgmt-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP Demo"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.allowed_mgmt_cidr
  ingress_rules       = ["https-443-tcp", "https-8443-tcp", "ssh-tcp"]

  ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.bigip_mgmt_sg.this_security_group_id
    }
  ]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}

data "aws_network_interface" "bar" {
  count = length(module.bigip.public_nic_ids)
  id    = module.bigip.public_nic_ids[count.index]
}
