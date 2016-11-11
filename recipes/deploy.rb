# Deploy the application.
#
# We are using the Poise Application family of cookbooks: https://github.com/poise/application
#

Chef::Log.info("The Backscratchers deploy recipe called")
include_recipe 'bs::report'

instance = search('aws_opsworks_instance', 'self:true').first
app = search('aws_opsworks_app', 'shortname:backscratchers').first
elb = search('aws_opsworks_elastic_load_balancer').first
db = search('aws_opsworks_rds_db_instance').first
secrets = node['secrets']
if node.has_key? 'rds' # Override the OpsWorks RDS info, so we are not always stuck with the AWS RDS info provided by default.
  db = node['rds']
end

application '/srv/backscratchers' do
  owner 'ubuntu'
  group 'www-data'

  ruby 'backscratchers' do
    provider :ruby_build
    version '2.2.5'
  end

  git do
    repository app['app_source']['url']
    deploy_key app['app_source']['ssh_key']
    revision app['app_source']['revision']
  end

  bundle_install do
    deployment true
    without %w{development test}
  end

  database_name = app['data_sources'].first['database_name']
  database_name ||= db.fetch('database_name')
  rails do
    rails_env app['environment']['RAILS_ENV']
    database({
      adapter: 'mysql2',
      host: db['address'],
      username: db['db_user'],
      password: db['db_password'],
      database: database_name
    })
  end

  ruby_execute 'whenever' do
    ruby '/opt/ruby_build/builds/backscratchers/bin/ruby'
    user 'root'
    environment({ 'PATH' => '/opt/ruby_build/builds/backscratchers/lib/ruby/gems/2.1.0/bin:/opt/ruby_build/builds/backscratchers/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games' }) # We have to set the path correctly, otherwise it will not be passed in to the whenever gem, and therefore not passed in to cron.
    command %Q{bin/whenever --update-crontab --roles #{instance['role'].join(',')} --set 'environment=#{app['environment']['RAILS_ENV']}' --user www-data}
  end

  directory '/srv/backscratchers/public/.well-known' do # Create directories for letsencrypt ACME challenge responses...
    mode 0755
    user 'ubuntu'
    group 'www-data'
  end
  directory '/srv/backscratchers/public/.well-known/acme-challenge' do # ... .
    mode 0755
    user 'ubuntu'
    group 'www-data'
  end
end

file '/srv/backscratchers/.ruby-version' do # Override .ruby-version so it’s got the name poise-ruby-build assigns.
  content 'backscratchers'
end

template '/srv/backscratchers/config/secrets.yml' do # Access to third-party APIs will need the appropriate secret keys.
  source 'secrets.yml.erb'
  mode 0640
  user 'ubuntu'
  group 'www-data'
  variables(vars: secrets, elb: elb, environment: app['environment']['RAILS_ENV'])
end

if secrets['xero'].has_key?('live_privatekey') # Access to the Xero API will need the appropriate key file.
  file '/srv/backscratchers/config/xero_live_privatekey.pem' do
    Chef::Log.info 'Creating xero_live_privatekey.pem'
    content secrets['xero']['live_privatekey']
    mode 0640
    user 'ubuntu'
    group 'www-data'
  end
elsif secrets['xero'].has_key?('test_privatekey')
  file '/srv/backscratchers/config/xero_test_privatekey.pem' do
    Chef::Log.info 'Creating xero_test_privatekey.pem'
    content secrets['xero']['test_privatekey']
    mode 0640
    user 'ubuntu'
    group 'www-data'
  end
end

service 'nginx' do # The site has changed, so NGINX needs to be restarted to pick this up.
  action :restart
end
execute 'curl 0.0.0.0/healthcheck' # Make sure Passenger has actually started and is serving things.
execute 'chown -R ubuntu:www-data /srv/backscratchers/log' # Log files have to be owned by the web user.
execute 'chmod -R ug+w /srv/backscratchers/log' # Log files must be writeable.

service 'delayed_job' do # Restart delayed_job to pick up any changes.
  action [:enable, :restart]
end

ruby_execute 'heartbeat' do # Say hello.
  ruby '/opt/ruby_build/builds/backscratchers/bin/ruby'
  cwd '/srv/backscratchers'
  environment({ 'RAILS_ENV' => app['environment']['RAILS_ENV'] }) 
  command %Q{bin/rake admin:heartbeat}
end
