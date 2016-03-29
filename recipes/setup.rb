Chef::Log.info("The Backscratchers setup recipe called")

Chef::Log.info("Updating APT")
include_recipe 'apt::default'

# Install Passenger, see
# https://www.phusionpassenger.com/library/install/nginx/install/oss/trusty/
Chef::Log.info("Passenger setup")
# Install dependencies.
package 'apt-transport-https'
package 'ca-certificates'
# Add the Passenger APT repository.
apt_repository 'passenger' do
  uri 'https://oss-binaries.phusionpassenger.com/apt/passenger'
  distribution 'trusty'
  components ['main']

  keyserver 'keyserver.ubuntu.com'
  key '561F9B9CAC40B2F7'
end
# Install Passenger itself, plus nginx extras.
package 'nginx-extras'
package 'passenger'

Chef::Log.info("NGINX setup")
package 'nginx'
service 'nginx' do
  action [:enable, :start]
end

