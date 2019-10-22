export BIGIPHOST0=`terraform output --json | jq '.bigip_mgmt_public_ips.value[0]' | sed 's/"//g'`
export BIGIPMGMTPORT=`terraform output --json | jq '.bigip_mgmt_port.value' | sed 's/"//g'`
export BIGIPPASSWORD=`terraform output --json | jq '.bigip_password.value' | sed 's/"//g'`
export JUMPHOSTIP=`terraform output --json | jq '.jumphost_ip.value[0]' | sed 's/"//g'`
echo connect at https://$BIGIPHOST0:$BIGIPMGMTPORT with $BIGIPPASSWORD
echo connect to jumphost at with
echo ssh -i "tfdemo.pem" ubuntu@$JUMPHOSTIP