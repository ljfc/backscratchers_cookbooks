# Set up the development environment specifically.
#

Chef::Log.info("The Backscratchers development recipe called")

instance = search('aws_opsworks_instance', 'self:true').first
app = search('aws_opsworks_app', 'shortname:backscratchers').first
elb = search('aws_opsworks_elastic_load_balancer').first
db = search('aws_opsworks_rds_db_instance').first
secrets = node['secrets']
if node.has_key? 'rds' # Override the OpsWorks RDS info, so we are not always stuck with the AWS RDS info provided by default.
  db = node['rds']
end

# Additional config data for the test environment.
test_db = node['test_db']
test_secrets = node['test_secrets']

# Dev version of application
application '' do
  owner 'ubuntu'
  group 'www-data'

  ruby 'backscratchers_dev' do
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
    # Include development and test gems ∵ this is the development environment.
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

end

file '/srv/dev/.ruby-version' do # Override .ruby-version so it’s got the name poise-ruby-build assigns.
  content 'backscratchers_dev'
end

template '/srv/dev/config/secrets.yml' do # Access to third-party APIs will need the appropriate secret keys.
  source 'secrets.yml.erb'
  mode 0640
  user 'ubuntu'
  group 'www-data'
  variables(vars: secrets, elb: elb, environment: app['environment']['RAILS_ENV'])
end

if secrets['xero'].has_key?('live_privatekey') # Access to the Xero API will need the appropriate key file.
  file '/srv/dev/config/xero_live_privatekey.pem' do
    Chef::Log.info 'Creating xero_live_privatekey.pem'
    content secrets['xero']['live_privatekey']
    mode 0640
    user 'ubuntu'
    group 'www-data'
  end
elsif secrets['xero'].has_key?('test_privatekey')
  file '/srv/dev/config/xero_test_privatekey.pem' do
    Chef::Log.info 'Creating xero_test_privatekey.pem'
    content secrets['xero']['test_privatekey']
    mode 0640
    user 'ubuntu'
    group 'www-data'
  end
end


# General setup.

# bash needs to be configured to use chruby with this user.
directory '/home/vagrant/.bash_extras' do # Add dir for bash extras: additional tweaks to bash can be made by adding things to this dir.
  owner 'vagrant'
  group 'vagrant'
  mode '0700'
end
file '/home/vagrant/.bash_profile' do # Add .bash_profile to pull in extra config scripts from .bash_extras, and the .bashrc non-login settings.
  content %Q{[[ -r ~/.bash_extras ]] && . ~/.bash_extras/*
[[ -r ~/.bashrc ]] && . ~/.bashrc
}
  owner 'vagrant'
  group 'vagrant'
  mode '0600'
end
file '/home/vagrant/.bash_extras/default' do
  content %Q{# This is a dummy file to prevent bash complaining because this directoy is empty.}
  owner 'vagrant'
  group 'vagrant'
  mode '0600'
end

template '/home/vagrant/.irbrc' do
  source 'irbrc.erb'
  mode 0644
  owner 'vagrant'
  group 'vagrant'
end

# Previous, manual, application setup.

#ruby_runtime 'ruby-2.2.5' do
#  provider :ruby_build
#  version '2.2.5'
#end

#ruby_gem 'bundler'

#bundle_install '/vagrant/Gemfile' do
#  user 'vagrant'
#  ruby 'ruby-2.2.5'
#  jobs 3
#end

#execute 'bundle install' do
#  user 'vagrant'
#  cwd '/vagrant'
#end

# `bundle install` overwrites the Spring bin stubs, so we must recreate them.
#execute 'bundle exec bin/spring binstub --all' do
#  user 'vagrant'
#  cwd '/vagrant'
#end

#template '/vagrant/config/database.yml' do
#  source 'database_dev.yml.erb'
#  mode 0640
#  user 501
#  group 'dialout'
#  variables(dev: db, test: test_db)
#end

#template '/vagrant/config/secrets.yml' do
#  source 'secrets_dev.yml.erb'
#  mode 0640
#  user 501
#  group 'dialout'
#  variables(dev: secrets, test: test_secrets)
#end

#file '/vagrant/config/xero_test_privatekey.pem' do
#  content secrets['xero']['test_privatekey']
#  mode 0640
#  user 501
#  group 'dialout'
#end

