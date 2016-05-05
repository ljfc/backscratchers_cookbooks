# Set up a server to run The Backscratchers application.
#

Chef::Log.info("The Backscratchers setup recipe called")
include_recipe 'bs::report'

instance = search('aws_opsworks_instance', 'self:true').first
app = search('aws_opsworks_app', 'shortname:backscratchers').first
db = search('aws_opsworks_rds_db_instance').first
secrets = node['secrets']
if node.has_key? 'rds' # Override the OpsWorks RDS info, so we are not always stuck with the AWS RDS info provided by default.
  db = node['rds']
end

include_recipe 'apt::default'

template '/etc/logrotate.d/backscratchers' do # Rotate our custom logs.
  source 'logrotate.erb'
  variables(environment: app['environment']['RAILS_ENV'])
  mode 0644
end

# Install Passenger, see
# https://www.phusionpassenger.com/library/install/nginx/install/oss/trusty/
apt_repository 'passenger' do # Add the Passenger APT repository.
  uri 'https://oss-binaries.phusionpassenger.com/apt/passenger'
  distribution 'trusty'
  components ['main']

  keyserver 'keyserver.ubuntu.com'
  key '561F9B9CAC40B2F7'
end
package 'passenger' # Rails application server which runs alongside the NGINX web server.

package 'nginx-extras' # The -extras version includes a bunch of extra modules, and is the version Passenger recommend.
template '/etc/nginx/nginx.conf' do # Configure NGINX as we want. This is just the generic config for the layer, NOT site config.
  source 'nginx.conf.erb'
  mode 0644
end
template '/etc/nginx/sites-available/backscratchers' do # Tell NGINX how to serve the site.
  source 'nginx_backscratchers.erb'
  variables(environment: app['environment']['RAILS_ENV'], server_name: app['domains'].first)
  mode 0644
end
file '/etc/nginx/sites-enabled/default' do # Prevent it from serving the default NGINX page.
  action :delete
end
link '/etc/nginx/sites-enabled/backscratchers' do # Tell NGINX to actually serve the site.
  mode 0644
  to '/etc/nginx/sites-available/backscratchers'
end
service 'nginx' do
  action [:enable, :restart]
end

package 'libmysqlclient-dev' # Required for MySQL database access.

execute 'download_chruby' do # chruby is used to switch to the correct Ruby for running an application.
  cwd '/home/ubuntu'
  command %Q{wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz && tar -xzvf chruby-0.3.9.tar.gz}
end
execute 'install_chruby' do
  cwd '/home/ubuntu/chruby-0.3.9'
  command %Q{make install}
end

template '/etc/bash.bashrc' do # bash needs to be configured to use chruby.
  source 'bash.bashrc.erb'
  mode 0644
  variables(environment: app['environment']['RAILS_ENV'])
end
directory '/home/ubuntu/.bash_extras' do # Add dir for bash extras: additional tweaks to bash can be made by adding things to this dir.
  owner 'ubuntu'
  group 'ubuntu'
  mode '0700'
end
file '/home/ubuntu/.bash_profile' do # Add .bash_profile to pull in extra config scripts from .bash_extras, and the .bashrc non-login settings.
  content %Q{[[ -r ~/.bash_extras ]] && . ~/.bash_extras/*
[[ -r ~/.bashrc ]] && . ~/.bashrc
}
  owner 'ubuntu'
  group 'ubuntu'
  mode '0600'
end
file '/home/ubuntu/.bash_extras/default' do
  content %Q{# This is a dummy file to prevent bash complaining because this directoy is empty.}
  owner 'ubuntu'
  group 'ubuntu'
  mode '0600'
end

template '/etc/init/delayed_job.conf' do
  source 'delayed_job.conf.erb'
  mode 0400
  variables(environment: app['environment']['RAILS_ENV'])
end

package 'ghostscript' # Dragonfly gem uses this to make thumbnails from PDFs.
package 'imagemagick' # Dragonfly gem uses this to make thumbnails. Install it after the above so it includes Ghostscript (this may not in fact be necessary, but hey-ho).
template '/etc/ImageMagick/policy.xml' do # Restrict vulnerable coders, see https://imagetragick.com
  source 'imagemagick_policy.xml.erb'
  mode 0644
end

package 'awscli' # We need to interact with AWS for things like sharing letsencrypt credentials.
directory '/root/.aws' do
  mode 0700
end
file '/root/.aws/config' do
  content %Q{[default]
aws_access_key_id = #{secrets['s3_credentials']['access_key_id']}
output = json
region = #{secrets['s3_credentials']['region']}
aws_secret_access_key = #{secrets['s3_credentials']['secret_access_key']}
}
  mode 0600
end

template '/home/ubuntu/.irbrc' do
  source 'irbrc.erb'
  mode 0644
  owner 'ubuntu'
  group 'ubuntu'
end
