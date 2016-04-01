# Set up a server.
#

Chef::Log.info("The Backscratchers setup recipe called")
include_recipe 'bs::report'

Chef::Log.info("Updating APT")
include_recipe 'apt::default'

# Install Passenger, see
# https://www.phusionpassenger.com/library/install/nginx/install/oss/trusty/
Chef::Log.info("Passenger setup")
# Install dependencies.
#package 'apt-transport-https'
#package 'ca-certificates'
# Add the Passenger APT repository.
apt_repository 'passenger' do
  uri 'https://oss-binaries.phusionpassenger.com/apt/passenger'
  distribution 'trusty'
  components ['main']

  keyserver 'keyserver.ubuntu.com'
  key '561F9B9CAC40B2F7'
end
package 'passenger'

Chef::Log.info("NGINX setup")
package 'nginx-extras' # The -extras version includes a bunch of extra modules, and is the version Passenger recommend.
service 'nginx' do
  action [:enable, :start]
end

Chef::Log.info("MySQL setup")
package 'libmysqlclient-dev'
