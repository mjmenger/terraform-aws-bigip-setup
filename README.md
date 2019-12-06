# Demo deployment of BIG-IPs using Terraform
# Pre-Req
This example creates the following resources inside of AWS.  Please ensure your IAM user or IAM Role has privileges to create these objects.

**Note 1:** This example requires 4 Elastic IPs, please ensure your EIP limit on your account can accommodate this (information on ElasticIP limits can be found at https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_ec2)
 - AWS VPC
 - AWS Route Tables
 - AWS Nat Gateways
 - AWS Elastic IPs
 - AWS EC2 Instances
 - AWS Subnets
 - AWS Security Groups

 **Note 2:** In order to use this demo your AWS account must be subscribed to the F5 AMI and its associated terms and conditions. If your account is not subscribed, the first time ```terraform apply``` is run you will receive an error similar to the following:

 **Error:** Error launching source instance: OptInRequired: In order to use this AWS Marketplace product you need to accept terms and subscribe. To do so please 
visit https://aws.amazon.com/marketplace/pp?sku=XXXXXXXXXXXXXXXXXXXXXXXX

The url embedded within the error message will load the appropriate location in order to subscribe the AWS account to the F5 AMI.
After subscribing, re-run the ```terraform apply``` command and the error should not occur again.

 **Note 3:** An authentication token must be generated and recorded as documented below in order to access the modules required by this demo
https://www.terraform.io/docs/commands/cli-config.html
- Log into terraform.io
- Go to Account > User Settings > Tokens
- Record token in safe place
# 1. Running Using a Docker container
You can choose to run this from your workstation or a container although container will be much more straight forward to get working. Follow the instructions below as appropriate;

**Docker Container Setup**

**Note:** Port 8089 is opened in order to use the gui of the locust load generating tool should you choose to use it.

**Using Docker**
Deploy an ubuntu jumpbox and install Docker CE - 
  - sudo apt install apt-transport-https ca-certificates curl software-properties-common
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  - sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic test"
  - sudo apt update
  - sudo apt upgrade
  - sudo apt install docker-ce
  - docker -v

**Using your workstation**
  - install Terraform https://learn.hashicorp.com/terraform/getting-started/install.html
  - install inpsec https://www.inspec.io/downloads/
  - install locust https://docs.locust.io/en/stable/installation.html
  - install jq https://stedolan.github.io/jq/download/
  - if on a Windows workstation, install Putty for scp support https://putty.org
# 2. Configuring Docker on jumphost: 
- cd $home
- git clone https://github.com/dober-man/terraform-aws-bigip-setup.git
- cd terraform-aws-bigip-setup/
- sudo docker run -it -v $(pwd):/workspace -p 8089:8089 mmenger/tfdemoenv:1.6.2 /bin/bash

**Note:** -v is volume option and maps host directory (bi-directionally and dynamically) to allow host to share files into guest container. Now all tools from repo are available in the docker container - any other files put into /home/ubuntu/terraform-aws-bigip-setup on the jumpbox will replicate dynamically to the container workspace directory. 
# 3. Configure Access Credentials
#Created new user in AWS IAM and granted admin access and saved keys for use below
#starting from within the clone of this repository on the jumphost (/home/ubuntu/terraform-aws-bigip-setup)
vi secrets.auto.tfvars

enter the following in the *secrets.auto.tfvars* file

AccessKeyID         = "<AN ACCESS KEY FOR YOUR AWS ACCOUNT>" 
SecretAccessKey     = "<THE SECRET KEY ASSOCIATED WITH THE AWS ACCESS KEY>" 
ec2_key_name        = "<THE NAME OF AN AWS KEY PAIR WHICH IS ASSOCIATE WITH THE AWS ACOUNT>"
ec2_key_file        = "<THE PATH TO AN SSH KEY FILE USED TO CONNECT TO THE UBUNTU SERVER ONCE IT IS CREATED. NOTE: THIS PATH SHOULD BE RELATIVE TO THE CONTAINER ROOT>"

save the file and quit vi

#Example
AccessKeyID         = "AKIAUEKXXXXXXITHV"
SecretAccessKey     = "+CXMydN+DJXXXXXXSq2MWQlA6o/+fkSS"
ec2_key_name        = "bhs-f5aws"
ec2_key_file        = "./bhs-f5aws.pem"

* need to copy pem file to jump host to terraform directory if not doing this from local machine and put mapping in ec2_key_file description above (/home/ubuntu/terraform-aws-bigip-setup)
# 4. Setup 
#initialize Terraform
#scans all tf files and looks for references to modules and providers and pulls down any necessary code
```terraform init```
#creates .terraform hidden directory
#build the BIG-IPS and the underpinning infrastructure
#terraform plan - will show what would happen under ```terraform apply``` without adding the deploy option
```terraform apply```
#terraform checks three things; 1 .tf files, 2 terraform state files (.tfstate) and 3 looks at what is actually built - (it logs into aws and checks for what has been built that it believes should exist)
#Next terraform creates a "plan"
#```terraform apply``` always shows a plan and item count - double check that this looks right)
#Ex: Plan: 86 to add, 0 to change, 0 to destroy.
#This builds the entire infrastructure 
```Depending upon how you intend to use the environment you may need to wait after Terraform is complete. The configuration of the  BIG-IPs is completed asynchoronously. If you need the BIG-IPs to be fully configured before proceeding, the following Inspec tests validate the connectivity of the BIG-IP and the availability of the management API end point.```
# 5. Check the status of the BIG-IPs
#these steps can also be performed using ./runtests.sh
````terraform output --json > inspec/bigip-ready/files/terraform.json````
````inspec exec inspec/bigip-ready````
once the tests all pass the BIG-IPs are ready
#12-06 getting an error about telemetry streaming module not available. Per Mark Menger - [The telemetry streaming error is actually expected at this time since the terraform build doesn't install TS.
​The ansible playbook does and then the TS tests would pass

If terraform returns an error, rerun ```terraform apply```.
# 6. Log into the BIG-IP
#find the connection info for the BIG-IP
#these steps can also be performed by using ./findthehosts.sh
export BIGIPHOST0=`terraform output --json | jq -r '.bigip_mgmt_public_ips.value[0]'`
export BIGIPMGMTPORT=`terraform output --json | jq -r '.bigip_mgmt_port.value'`
export BIGIPPASSWORD=`terraform output --json | jq -r '.bigip_password.value'`
export JUMPHOSTIP=`terraform output --json | jq -r '.jumphost_ip.value[0]'`
echo connect at https://$BIGIPHOST0:$BIGIPMGMTPORT with $BIGIPPASSWORD
echo connect to jumphost at with
echo ssh -i "<THE AWS KEY YOU IDENTIFIED ABOVE>" ubuntu@$JUMPHOSTIP

connect to the BIGIP at https://<bigip_mgmt_public_ips>:<bigip_mgmt_port>
login as user:admin and password: <bigip_password>
# 7. Teardown
When you are done using the demo environment you will need to decommission it
```terraform destroy```

as a final step check that terraform doesn't think there's anything remaining
```terraform show```
this should return a blank line

