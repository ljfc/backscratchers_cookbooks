# Configure the system.
#
# We are using the Poise Application family of cookbooks: https://github.com/poise/application
#

Chef::Log.info("The Backscratchers configure recipe called")
include_recipe 'bs::report'

app = search('aws_opsworks_app', 'shortname:backscratchers').first
db = search('aws_opsworks_rds_db_instance').first
secrets = node['secrets']


Chef::Log.info("NGINX configuration")

file '/etc/nginx/nginx.conf' do
  mode 0644
  content %Q{
user www-data;
worker_processes 4;
pid /run/nginx.pid;
events {
  worker_connections 768;
}
http {
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
  ssl_prefer_server_ciphers on;

  access_log /var/log/nginx/access.log;
  error_log /var/log/nginx/error.log;

  gzip on;
  gzip_disable "msie6";

  passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
  passenger_ruby /usr/bin/passenger_free_ruby;

  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
}
  }
end

file '/etc/nginx/sites-available/backscratchers' do
  mode 0644
  content %Q{
server {
  listen 80;
  listen [::]:80;

  server_name #{app['domains'].first};
  root /srv/backscratchers/public;
  passenger_enabled on;
  rails_env #{app['environment']['RAILS_ENV']};

  client_max_body_size 30M;

  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root html;
  }
}
  }
end

file '/etc/nginx/sites-enabled/default' do
  action :delete
end

link '/etc/nginx/sites-enabled/backscratchers' do
  mode 0644
  to '/etc/nginx/sites-available/backscratchers'
end

service 'nginx' do
  Chef::Log.info("NGINX restart")
  action [:enable, :restart]
end
