# Set up the development environment specifically.
#

Chef::Log.info("The Backscratchers Development default recipe called")

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

# Application setup.

ruby_runtime 'ruby-2.2.5' do
  provider :ruby_build
  version '2.2.5'
end

ruby_gem 'bundler'

bundle_install '/vagrant/Gemfile' do
  user 'vagrant'
  ruby 'ruby-2.2.5'
  jobs 3
end

execute 'bundle install' do
  user 'vagrant'
  cwd '/vagrant'
end

# `bundle install` overwrites the Spring bin stubs, so we must recreate them.
execute 'bundle exec bin/spring binstub --all' do
  user 'vagrant'
  cwd '/vagrant'
end

template '/vagrant/config/database.yml' do
  source 'database_dev.yml.erb'
  mode 0640
  user 501
  group 'dialout'
  variables(dev: db, test: test_db)
end

template '/vagrant/config/secrets.yml' do
  source 'secrets_dev.yml.erb'
  mode 0640
  user 501
  group 'dialout'
  variables(dev: secrets, test: test_secrets)
end

file '/vagrant/config/xero_test_privatekey.pem' do
  content secrets['xero']['test_privatekey']
  mode 0640
  user 501
  group 'dialout'
end

