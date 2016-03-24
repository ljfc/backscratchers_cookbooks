Chef::Log.info("The Backscratchers setup recipe called")

Chef::Log.info("Updating APT")
include_recipe 'apt::default'

# Install Passenger, see
# https://www.phusionpassenger.com/library/install/nginx/install/oss/trusty/
Chef::Log.inf("Installing Passenger")
package 'apt-transport-https'
package 'ca-certificates'

Chef::Log.info("Installing NGINX")
package 'nginx'
service 'nginx' do
  action [:enable, :start]
end

