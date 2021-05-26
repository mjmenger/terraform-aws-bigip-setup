

data "aws_ami" "latest-ubuntu" {
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


module "jumphost" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = format("%s-demo-jumphost-%s", var.prefix, random_id.id.hex)
  instance_count = length(var.azs)

  ami                         = data.aws_ami.latest-ubuntu.id
  associate_public_ip_address = true
  instance_type               = var.ec2_ubuntu_type
  key_name                    = var.ec2_key_name
  monitoring                  = false
  vpc_security_group_ids      = [module.jumphost_sg.this_security_group_id]
  subnet_ids                  = module.vpc.public_subnets


  # build user_data file from template
  user_data = templatefile("${path.module}/jumphost.userdata.tmpl",{})

  # this box needs to know the ip address of the bigip and the juicebox host
  # it also needs to know the bigip username and password to use

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Application = var.prefix
  }
}

#
# Create a security group for the jumphost
#
module "jumphost_sg" {
  source = "terraform-aws-modules/security-group/aws"
  version = "3.18.0"
  name        = format("%s-jumphost-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP Demo"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.allowed_mgmt_cidr
  ingress_rules       = ["https-443-tcp", "ssh-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 3300
      to_port     = 3300
      protocol    = "tcp"
      description = "Juiceshop ports"
      cidr_blocks = join(",",var.allowed_mgmt_cidr)
    },
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "Juiceshop ports"
      cidr_blocks = join(",",var.allowed_mgmt_cidr)
    },
  ]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}
#
# Create and place the inventory.yml file for the ansible demo
#
resource "null_resource" "transfer" {
  count = length(var.azs)
  provisioner "file" {
    content     = templatefile(
      "${path.module}/hostvars_template.yml",
          {
            bigip_host_ip          = join(",",element(module.bigip.mgmt_addresses,count.index))#bigip_host_ip          = module.bigip.mgmt_public_ips[count.index]  the ip address that the bigip has on the management subnet
            bigip_host_dns         = module.bigip.mgmt_public_dns[count.index] # the DNS name of the bigip on the public subnet
            bigip_domain           = "${var.region}.compute.internal"
            bigip_username         = "admin"
            bigip_password         = random_password.password.result
            ec2_key_name           = var.ec2_key_name
            ec2_username           = "ubuntu"
            log_pool               = cidrhost(cidrsubnet(var.cidr,8,count.index + var.internal_subnet_offset),250)
            bigip_external_self_ip = element(flatten(data.aws_network_interface.bar[count.index].private_ips),0) # the ip address that the bigip has on the public subnet
            bigip_internal_self_ip = join(",",element(module.bigip.private_addresses,count.index)) # the ip address that the bigip has on the private subnet
            juiceshop_virtual_ip   = element(flatten(data.aws_network_interface.bar[count.index].private_ips),1)
            grafana_virtual_ip     = element(flatten(data.aws_network_interface.bar[count.index].private_ips),2)
            appserver_gateway_ip   = cidrhost(cidrsubnet(var.cidr,8,count.index + var.internal_subnet_offset),1)
            appserver_guest_ip     = module.dockerhost.private_ip[count.index]
            appserver_host_ip      = module.jumphost.private_ip[count.index]   # the ip address that the jumphost has on the public subnet
            bigip_dns_server       = "8.8.8.8"
          }
    )

    destination = "~/inventory.yml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ec2_key_file)
      host        = module.jumphost.public_ip[count.index]
    }
  }
}



resource "aws_eip" "juiceshop" {
  count                     = length(var.azs)
  # an occasional race condition with between creating the ElasticIP addresses 
  # and the BIG-IP instances occurs causing the following error
  # Error: Failure associating EIP: IncorrectInstanceState: The pending-instance-creation instance to which 'eni-xxxxxxxxxxxxxxxxx' is attached is not in a valid state for this operation
  # https://github.com/terraform-providers/terraform-provider-aws/issues/6189
  # the following depends_on is intended as a workaround for this condition
  # if the error still occurs an additional 'terraform apply' completes the environment build
  depends_on                = [module.bigip]
  vpc                       = true
  network_interface         = data.aws_network_interface.bar[count.index].id
  associate_with_private_ip = element(flatten(data.aws_network_interface.bar[count.index].private_ips),1)
  tags                      = {
    Name = format("%s-juiceshop-eip-%s%s", var.prefix, random_id.id.hex,count.index)
  }
}

resource "aws_eip" "grafana" {
  count                     = length(var.azs)
  # an occasional race condition with between creating the ElasticIP addresses 
  # and the BIG-IP instances occurs causing the following error
  # Error: Failure associating EIP: IncorrectInstanceState: The pending-instance-creation instance to which 'eni-xxxxxxxxxxxxxxxxx' is attached is not in a valid state for this operation
  # https://github.com/terraform-providers/terraform-provider-aws/issues/6189
  # the following depends_on is intended as a workaround for this condition
  # if the error still occurs an additional 'terraform apply' completes the environment build
  depends_on                = [module.bigip]
  vpc                       = true
  network_interface         = data.aws_network_interface.bar[count.index].id
  associate_with_private_ip = element(flatten(data.aws_network_interface.bar[count.index].private_ips),2)
  tags                      = {
    Name = format("%s-grafana-eip-%s%s", var.prefix, random_id.id.hex,count.index)
  }

}
