#!/usr/bin/env bash
export AWS_PROFILE=default
########################
# include the magic
########################
if [ ! -f "demo-magic.sh" ]; then
  wget https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh >> /dev/null 2>&1
fi
. ./demo-magic.sh

TYPE_SPEED=20

pei "terraform apply -auto-approve"

export BIGIPHOST0=`terraform output --json | jq -r '.bigip_mgmt_public_ips.value[0]'`
export BIGIPHOST1=`terraform output --json | jq -r '.bigip_mgmt_public_ips.value[1]'`
export BIGIPMGMTPORT=`terraform output --json | jq -r '.bigip_mgmt_port.value'`
export BIGIPPASSWORD=`terraform output --json | jq -r '.bigip_password.value'`
export EC2KEYNAME=`terraform output --json | jq -r '.ec2_key_name.value'`
export EC2KEYFILE=`terraform output --json | jq -r '.ec2_key_file.value'`
export JUMPHOSTIP0=`terraform output --json | jq -r '.jumphost_ip.value[0]'`
export JUMPHOSTIP1=`terraform output --json | jq -r '.jumphost_ip.value[1]'`
export JUICESHOP0=`terraform output --json | jq -r '.juiceshop_ip.value[0]'`
export JUICESHOP1=`terraform output --json | jq -r '.juiceshop_ip.value[1]'`
export GRAFANA0=`terraform output --json | jq -r '.grafana_ip.value[0]'`
export GRAFANA1=`terraform output --json | jq -r '.grafana_ip.value[1]'`

echo 'test the results'
pei "./runtests.sh"
PROMPT_TIMEOUT=120
echo "that probably failed so let's wait for a couple of minutes"
wait 
echo "let's test again - press enter when you're ready"
pe "./runtests.sh"
PROMPT_TIMEOUT=0
echo "that should have succeeded - let's test one more time to be sure - press enter when you're ready" 
pe "./runtests.sh"

echo check out the vanilla BIG-IP at https://$BIGIPHOST0:$BIGIPMGMTPORT with $BIGIPPASSWORD

echo "prepare the environment - copy over the private key - press enter when you're ready"
pe "scp -o 'StrictHostKeyChecking no' -i $EC2KEYFILE $EC2KEYFILE ubuntu@$JUMPHOSTIP0:~/$EC2KEYNAME.pem"
echo "prepare the environment - copy over the configuration script"
pei "scp -o 'StrictHostKeyChecking no' -i $EC2KEYFILE ./remoteconfiguration.sh ubuntu@$JUMPHOSTIP0:~/remoteconfiguration.sh"
echo "prepare the environment - remotely execute the configuration script"
pei "ssh -o 'StrictHostKeyChecking no' -i $EC2KEYFILE ubuntu@$JUMPHOSTIP0 ./remoteconfiguration.sh $JUICESHOP0"

echo "********"
echo connect to BIG-IP at https://$BIGIPHOST0:$BIGIPMGMTPORT with $BIGIPPASSWORD
echo check out the Juice Shop application behind the virtual server at http://$JUICESHOP0
echo review the telemetry data on the Grafana dashboard at http://$GRAFANA0
echo "********"
echo "clean up the environment when you're done - press enter when ready"
pe "terraform destroy -auto-approve"