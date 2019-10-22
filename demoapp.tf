
#
# Create the demo NGINX app
#
module "nginx-demo-app" {
  source  = "github.com/mjmenger/juiceshopmodule"
  #version = "0.1.2"

  prefix = format(
    "%s-%s",
    var.prefix,
    random_id.id.hex
  )
  ec2_key_name = var.ec2_key_name
  # associate_public_ip_address = true
  vpc_security_group_ids = [
    module.demo_app_sg.this_security_group_id
  ]
  vpc_subnet_ids     = module.vpc.private_subnets
  ec2_instance_count = 1
}



#
# Create a security group for demo app
#
module "demo_app_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-demo-app-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP Demo"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [var.cidr]
  ingress_rules       = ["all-all"]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}