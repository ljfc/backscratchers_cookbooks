Chef::Log.info("The Backscratchers deploy recipe called")

# Restart (or start) NGINX.
Chef::Log.info("NGINX deployment")
service 'nginx' do
  action :restart
end
