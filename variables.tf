variable "AccessKeyID" {}

variable "SecretAccessKey" {}

variable "prefix" {
  default = "tf-aws-bigip"
}

variable "region" {
  default = "us-east-2"
}

variable "azs" {
  default = ["us-east-2a", "us-east-2b"]
}

variable "cidr" {
  default = "10.0.0.0/16"
}

variable "allowed_mgmt_cidr" {
  default = "0.0.0.0/0"
}

variable "allowed_app_cidr" {
  default = "0.0.0.0/0"
}

variable "ec2_key_name" {
}

variable "ec2_key_file" {
}
