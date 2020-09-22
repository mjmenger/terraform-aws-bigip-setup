# copyright: 2018, The Authors

title "Verify BIG-IP availability"


# load data from Terraform output
# created by terraform output --json > inspec/bigip-ready/files/terraform.json
content = inspec.profile.file("terraform.json")
params = JSON.parse(content)

begin
  BIGIP_DNS       = params['bigip_mgmt_public_ips']['value']
  BIGIP_PORT      = params['bigip_mgmt_port']['value']
  BIGIP_PASSWORD  = params['bigip_password']['value']
rescue
  BIGIP_DNS       = []
  BIGIP_PORT      = ""
  BIGIP_PASSWORD  = ""
end

control "Connectivity" do
  impact 1.0
  title "BIGIP is reachable"

  BIGIP_DNS.each do |bigip_host|
    # can we reach the management port on the BIG-IP?
    describe host(bigip_host, port: BIGIP_PORT, protocol: 'tcp') do
        it { should be_reachable }
    end
  end
end 

control "Declarative Onboarding Available" do
  impact 1.0
  title "BIGIP has DO"

  BIGIP_DNS.each do |bigip_host|
    # is the declarative onboarding end point available?
    describe http("https://#{bigip_host}:#{BIGIP_PORT}/mgmt/shared/declarative-onboarding/info",
              auth: {user: 'admin', pass: BIGIP_PASSWORD},
              params: {format: 'html'},
              method: 'GET',
              ssl_verify: false) do
          its('status') { should cmp 200 }
          its('headers.Content-Type') { should match 'application/json' }
    end
    describe json(content: http("https://#{bigip_host}:#{BIGIP_PORT}/mgmt/shared/declarative-onboarding/info",
              auth: {user: 'admin', pass: BIGIP_PASSWORD},
              params: {format: 'html'},
              method: 'GET',
              ssl_verify: false).body) do
          its([0,'version']) { should eq '1.14.0' }
          its([0,'release']) { should eq '1' } # this should be replaced with a test using the json resource
    end
  end
end 

control "Application Services Available" do
  impact 1.0
  title "BIGIP has AS3"

  BIGIP_DNS.each do |bigip_host|
    # is the application services end point available?
    describe http("https://#{bigip_host}:#{BIGIP_PORT}/mgmt/shared/appsvcs/info",
              auth: {user: 'admin', pass: BIGIP_PASSWORD},
              params: {format: 'html'},
              method: 'GET',
              ssl_verify: false) do
          its('status') { should cmp 200 }
          its('headers.Content-Type') { should match 'application/json' }
    end
    describe json(content: http("https://#{bigip_host}:#{BIGIP_PORT}/mgmt/shared/appsvcs/info",
              auth: {user: 'admin', pass: BIGIP_PASSWORD},
              params: {format: 'html'},
              method: 'GET',
              ssl_verify: false).body) do
          its('version') { should eq '3.22.1' }
          its('release') { should eq '1' } # this should be replaced with a test using the json resource
    end
  end
end 

control "Telemetry Streaming Available" do
  impact 1.0
  title "BIGIP has TS"

  BIGIP_DNS.each do |bigip_host|
    # is the telemetry streaming end point available?
    describe http("https://#{bigip_host}:#{BIGIP_PORT}/mgmt/shared/telemetry/info",
              auth: {user: 'admin', pass: BIGIP_PASSWORD},
              params: {format: 'html'},
              method: 'GET',
              ssl_verify: false) do
          its('status') { should cmp 200 }
          its('headers.Content-Type') { should match 'application/json' }
    end
    describe json(content: http("https://#{bigip_host}:#{BIGIP_PORT}/mgmt/shared/telemetry/info",
              auth: {user: 'admin', pass: BIGIP_PASSWORD},
              params: {format: 'html'},
              method: 'GET',
              ssl_verify: false).body) do
          its('version') { should eq '1.14.0' }
          its('release') { should eq '2' } # this should be replaced with a test using the json resource
    end
  end
end 

