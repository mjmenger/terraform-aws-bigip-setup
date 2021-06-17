resource "local_file" "dotenv" {
  content  = <<EOF
bigip1=${module.bigip.mgmt_public_ips[0]}
bigip2=${module.bigip.mgmt_public_ips[1]}
user=admin
password=${random_password.password.result}
EOF
  filename = "${path.module}/.env"
}