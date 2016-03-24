Chef::Log.info("The Backscratchers setup recipe called")

Chef::Log.info("Setting up NGINX")
package 'nginx'
service 'nginx' do
  action [:enable, :start]
end

