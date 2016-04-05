# Deploy the site.
#
# We are using the Poise Application family of cookbooks: https://github.com/poise/application
#

Chef::Log.info("The Backscratchers deploy recipe called")
include_recipe 'bs::report'

app = search('aws_opsworks_app', 'shortname:backscratchers').first
db = search('aws_opsworks_rds_db_instance').first
secrets = node['secrets']

application '/srv/backscratchers' do
  Chef::Log.info("Deploying The Backscratchers")
  owner 'ubuntu'
  group 'www-data'

  ruby do
    provider :ruby_build
    version '2.1.3'
  end

  Chef::Log.info("Installing with git from #{app['app_source']['url']}")
  git do
    repository app['app_source']['url']
    deploy_key app['app_source']['ssh_key']
    revision app['app_source']['revision']
  end

  Chef::Log.info("Bundling gems")
  bundle_install do
    deployment true
    without %w{development test}
  end

  Chef::Log.info("Deploying rails app...")
  rails do
    Chef::Log.info("\t...using database #{db['db_instance_identifier']} at #{db['address']}")
    rails_env app['environment']['RAILS_ENV']
    Chef::Log.info "Setting database name to #{db['db_instance_identifier']}"
    database({
      adapter: 'mysql2',
      host: db['address'],
      username: db['db_user'],
      password: db['db_password'],
      database: app['data_sources'].first['database_name']
    })
  end
end

file '/srv/backscratchers/.ruby-version' do # Override .ruby-version so it’s got the name poise-ruby-build assigns.
  content 'backscratchers'
end

template '/srv/backscratchers/config/secrets.yml' do
  Chef::Log.info 'Processing template secrets.yml'
  source 'secrets.yml.erb'
  mode 0640
  user 'ubuntu'
  group 'www-data'
  variables(vars: secrets, environment: app['environment']['RAILS_ENV'])
end

if secrets['xero'].has_key?('live_privatekey')
  file '/srv/backscratchers/config/xero_live_privatekey.pem' do
    Chef::Log.info 'Creating xero_live_privatekey.pem'
    content secrets['xero']['live_privatekey']
    mode 0640
    user 'ubuntu'
    group 'www-data'
  end
end

if secrets['xero'].has_key?('test_privatekey')
  file '/srv/backscratchers/config/xero_test_privatekey.pem' do
    Chef::Log.info 'Creating xero_test_privatekey.pem'
    content secrets['xero']['test_privatekey']
    mode 0640
    user 'ubuntu'
    group 'www-data'
  end
end

service 'nginx' do
  Chef::Log.info("NGINX deployment")
  action :restart
end
