resource "local_file" "dotenv" {
    content = <<EOF
bigip1=${module.bigip.mgmt_public_ips[0]}
user=admin
password=${random_password.password.result}
EOF
    filename = "${path.module}/.env"
}