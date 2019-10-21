#
# Deploy the demo app on the BIG-IP using AS3
#
provider "bigip" {
  alias    = "bigip1"
  address  = format("https://%s:%s", module.bigip.mgmt_public_ips[0], module.bigip.mgmt_port)
  username = "admin"
  password = random_password.password.result
}


resource "bigip_as3" "as3-demo1" {
  provider = bigip.bigip1
  as3_json = templatefile(
    "${path.module}/as3.tmpl",
    {
      pool_members = jsonencode(module.nginx-demo-app.private_ips)
    }
  )
  tenant_name = "as3"
}

# provider "bigip" {
#   alias    = "bigip2"
#   address  = format("https://%s:%s", module.bigip.mgmt_public_ips[1], module.bigip.mgmt_port)
#   username = "admin"
#   password = random_password.password.result
# }

# resource "bigip_as3" "as3-demo2" {
#   provider = bigip.bigip2
#   as3_json = templatefile(
#     "${path.module}/as3.tmpl",
#     {
#       pool_members = jsonencode(module.nginx-demo-app.private_ips)
#     }
#   )
#   tenant_name = "as3"
# }
