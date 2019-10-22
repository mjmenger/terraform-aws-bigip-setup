terraform output --json > inspec/bigip-ready/files/terraform.json
inspec exec inspec/bigip-ready
