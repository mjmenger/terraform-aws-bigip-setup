data "aws_ami" "latest-ubuntu-docker" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


module "dockerhost" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = format("%s-demo-dockerhost-%s", var.prefix, random_id.id.hex)
  instance_count = length(var.azs)

  ami                         = data.aws_ami.latest-ubuntu-docker.id
  associate_public_ip_address = false
  instance_type               = var.ec2_ubuntu_type
  root_block_device = [
      {
        volume_type = "gp2"
        volume_size = 100
      },
    ]
  key_name                    = var.ec2_key_name
  monitoring                  = false
  vpc_security_group_ids      = [module.dockerhost_sg.this_security_group_id]
  subnet_ids                  = module.vpc.private_subnets


  user_data = templatefile("${path.module}/dockerhost.userdata.tmpl", {})

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Application = var.prefix
  }
}

#
# Create a security group for the jumphost
#
module "dockerhost_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"

  name        = format("%s-dockerhost-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP Demo"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [var.cidr]
  ingress_rules       = ["ssh-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 3030
      to_port     = 3030
      protocol    = "tcp"
      description = "grafana"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 3400
      to_port     = 3400
      protocol    = "tcp"
      description = "graphite"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 2003
      to_port     = 2003
      protocol    = "tcp"
      description = "graphite"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 2004
      to_port     = 2004
      protocol    = "tcp"
      description = "graphite"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 2023
      to_port     = 2023
      protocol    = "tcp"
      description = "graphite"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 2024
      to_port     = 2024
      protocol    = "tcp"
      description = "graphite"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 8125
      to_port     = 8125
      protocol    = "udp"
      description = "graphite"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 8126
      to_port     = 8126
      protocol    = "tcp"
      description = "graphite"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "graphite"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 9200
      to_port     = 9200
      protocol    = "tcp"
      description = "elastic search"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 9300
      to_port     = 9300
      protocol    = "tcp"
      description = "elastic search"
      cidr_blocks = var.cidr
    },
    {
      from_port   = 3300
      to_port     = 3300
      protocol    = "tcp"
      description = "juice shop"
      cidr_blocks = var.cidr
    },
  ]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}
