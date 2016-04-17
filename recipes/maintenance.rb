# Toggle maintenance mode.
#
# Default is to enable it.
#

Chef::Log.info("The Backscratchers maintenance mode recipe called")
include_recipe 'bs::report'

app = search('aws_opsworks_app', 'shortname:backscratchers').first
options = node['maintenance'] || {}
enable = options.has_key?('enable') ? options['enable'] : true
message = options.has_key?('message') ? options['message'] : "The Backscratchers is down for planned maintenance. Back soon!"
enable = false if enable == 'false'

Chef::Log.info("The Backscratchers going #{enable ? 'into' : 'out of'} maintenance mode")
Chef::Log.info("options hash is #{options.inspect}")
Chef::Log.info("enable option is #{enable.inspect}")

if enable

  Chef::Log.info("Setting up maintenance mode")

  directory '/srv/maintenance' do
    mode 0750
    user 'ubuntu'
    group 'www-data'
  end

  file '/srv/maintenance/index.html' do # Basic holding page for when the site is down for maintenance.
    mode 0640
    user 'ubuntu'
    group 'www-data'
    content %Q{<html><head><title>The Backscratchers</title></head>
  <body><p>#{message}</p></body>
</html>
    }
  end

  file '/srv/maintenance/healthcheck' do # This must exist or maintenance-mode servers will get pulled out of the load balancer!
    mode 0640
    user 'ubuntu'
    group 'www-data'
    content %Q{<html><head><title>The Backscratchers</title></head>
  <body><p>The Backscratchers is in maintenance mode</p></body>
</html>
    }
  end

  file '/etc/nginx/sites-available/maintenance' do
    mode 0644
    content %Q{
  server {
    listen 80;
    listen [::]:80;

    server_name #{app['domains'].first};
    root /srv/maintenance;
  }
    }
  end

  file '/etc/nginx/sites-enabled/backscratchers' do
    action :delete
  end

  link '/etc/nginx/sites-enabled/maintenance' do
    mode 0644
    to '/etc/nginx/sites-available/maintenance'
  end

else # disable

  Chef::Log.info("Tearing down maintenance mode")

  file '/etc/nginx/sites-enabled/maintenance' do
    action :delete
  end

  link '/etc/nginx/sites-enabled/backscratchers' do
    mode 0644
    to '/etc/nginx/sites-available/backscratchers'
  end

end

service 'nginx' do
  Chef::Log.info("NGINX maintenance mode restart")
  action :restart
end
