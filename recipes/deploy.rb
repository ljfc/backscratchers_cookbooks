Chef::Log.info("The Backscratchers deploy recipe called")

# Restart or start nginx.
Chef::Log.info("NGINX deployment")
service 'nginx' do
  if File.exists? '/opt/nginx/logs/nginx.pid' # TODO @leo Check what the correct path is for this on Ubuntu 14.04
    action :restart
  else
    action :start
  end
end
