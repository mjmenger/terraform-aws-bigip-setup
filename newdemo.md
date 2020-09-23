
1. clone this repository  
```git clone https://github.com/mjmenger/terraform-aws-bigip-setup```
1. checkout the feature branch  
```git checkout switch-to-20.04```  
this is necessary because the fix hasn't been promoted to the default branch yet.
1. edit **demo.sh**  
```code demo.sh```  
or  
```vi demo.sh```  
or whatever editor you prefer
1. change the name of the AWS_PROFILE  
```
#!/usr/bin/env bash
export AWS_PROFILE=<place the profile name here>
########################
# include the magic
```
5. save and close **demo.sh**  
in whatever way is appropriate to the tool you used  
1. start the demo  
```./demo.sh```  
At this point the terraform apply will run with the ```-auto-approve``` flag. When the apply is complete is will immediately run the inspec tests, which should fail. 
1. Wait for two minutes.  
If you want to skip the two minute pause, press enter. 
1. After the pause, press enter to run the tests again.  
You actually need to press enter twice, once to stage the next command and again to execute the command. 
1. Run the tests one last time.  
The previous run may have been successful, this will assure the tests have succeeded. You'll have to press enter once to stage the command and a second time to execute the command.
1. Check out the vanilla BIG-IP  
the management IP address and its password are provided. The BIG-IP will be in an unconfigured state.
1. Start configuring the environment  
you're prompted to "prepare the environment...". When you're ready, press enter to stage the command and enter again to execute the command.
1. Watch  
At this point the demo script will load the required private key and an environment configuration script, and then execute the configuration script remotely. At a high-level, this will:  
- clone the ansible repository
- copy the Terraform generated inventory into the cloned repository
- update the remote host with dependencies required by the Ansible playbook
- execute the Ansible playbook
- generate some load on the Juice Shop application
- run an attack on the WAF protected Juice Shop application  
13. Review the configured environment  
The environment configuration should now be complete. You are presented with the URLs of the BIG-IP, the Juice Shop virtual server, and the Grafana virtual server. The username and password for Grafana is admin:admin.
1. Dispose of the environment
When you're done exploring the environment, press enter to stage the destroy command and press enter again to execute the command.

