# Set up TLS encryption
#
# We are using letsencrypt.com and lukas2511/letsencrypt.sh
#

Chef::Log.info("The Backscratchers letsencrypt recipe called")

instance = search('aws_opsworks_instance', 'self:true').first
app = search('aws_opsworks_app', 'shortname:backscratchers').first
elb = search('aws_opsworks_elastic_load_balancer').first
db = search('aws_opsworks_rds_db_instance').first
secrets = node['secrets']
if node.has_key? 'rds' # Override the OpsWorks RDS info, so we are not always stuck with the AWS RDS info provided by default.
  db = node['rds']
end

if node.has_key?('letsencrypt') && instance['role'].include?('lead_server') # Only do any of this if letsencrypt config is present and this is the lead server.
  letsencrypt = node['letsencrypt']
  s3_uri = "s3://#{letsencrypt['s3_bucket']}/#{app['domains'].first}/#{letsencrypt['certificate_authority'].split('/').join('.')}/letsencrypt.sh"

  template '/usr/local/bin/letsencrypt.sh' do # Install the letsencrypt.sh script.
    source 'letsencrypt.sh.erb'
    mode 0700
  end
  directory '/etc/letsencrypt.sh' do # Create the letsencrypt directories for config and output...
    mode 0700
  end

  execute 'sync letsencrypt from s3' do # Pull down any config from S3.
    command "aws s3 sync #{s3_uri} /etc/letsencrypt.sh"
  end

  template  '/etc/letsencrypt.sh/config.sh' do # Configuration file.
    source 'letsencrypt_config.sh.erb'
    variables({ letsencrypt: letsencrypt })
    mode 0700
  end
  template '/etc/letsencrypt.sh/domains.txt' do
    source 'letsencrypt_domains.txt.erb'
    variables({ domains: (app['domains'] - ['backscratchers']) }) # Subtract the app shortname that AWS adds (annoyingly).
    mode 0600
  end
  # TODO @leo Make this conditionally push to AWS or not depending on whether there is an ELB.
  template  '/usr/local/etc/letsencrypt_hook.sh' do # Hook for deploying keys to ELB (or whatever)
    source 'letsencrypt_hook.sh.erb'
    variables({ letsencrypt: letsencrypt, elb: elb })
    mode 0700
  end

  letsencrypt_command = "letsencrypt.sh -c"

  execute letsencrypt_command # Run the command immediately to update if needed.
  cron 'run letsencrypt regularly' do
    command letsencrypt_command
    #weekday '4' # Thursday...
    #hour '11' # ...at 11am.
    #minute '0'
  end

  execute 'sync letsencrypt from s3' do # Push back up any changes to the config to S3.
    command "aws s3 sync /etc/letsencrypt.sh #{s3_uri}"
  end
end
