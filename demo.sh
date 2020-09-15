#!/usr/bin/env bash

########################
# include the magic
########################
. ../demomagic.sh

TYPE_SPEED=20

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

pei "scp -i $EC2KEYFILE $EC2KEYFILE ubuntu@$JUMPHOSTIP0:~/$EC2KEYNAME.pem"
pei "scp -i $EC2KEYFILE ./remotedemo.sh ubuntu@$JUMPHOSTIP0:~/remotedemo.sh"
pei "ssh -i $EC2KEYFILE ubuntu@$JUMPHOSTIP0 ./remotedemo.sh"
