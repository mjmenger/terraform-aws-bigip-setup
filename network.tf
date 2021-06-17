#
# Create the VPC 
# using directions from https://clouddocs.f5.com/cloud/public/v1/aws/AWS_multiNIC.html
#
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = format("%s-vpc-%s", var.prefix, random_id.id.hex)
  cidr                 = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs = var.azs

  # vpc public subnet used for external interface
  public_subnets = [for num in range(length(var.azs)) :
    cidrsubnet(var.cidr, 8, num + var.external_subnet_offset)
  ]

  # vpc private subnet used for internal 
  private_subnets = [
    for num in range(length(var.azs)) :
    cidrsubnet(var.cidr, 8, num + var.internal_subnet_offset)
  ]

  enable_nat_gateway = true

  # using the database subnet method since it allows a public route
  database_subnets = [
    for num in range(length(var.azs)) :
    cidrsubnet(var.cidr, 8, num + var.management_subnet_offset)
  ]
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  tags = {
    Name        = format("%s-vpc-%s", var.prefix, random_id.id.hex)
    Terraform   = "true"
    Environment = "dev"
  }
}



