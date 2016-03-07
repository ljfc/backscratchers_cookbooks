# AWS OpsWorks recipe to be excuted when configuring the Backscratchers application.
#
# This should be run as an additional recipe on a standard Rails App Server layer.
#
node[:deploy].each do |application, deploy|

  Chef::Log.info "Running backscratchers::configure for #{application}"
  deploy.each do |key, value|
    Chef::Log.info "     #{key}: #{value}"
  end
  Chef::Log.info application.inspect

  unless application == "backscratchers"
    Chef::Log.info "Skipping backscratchers::configure for #{application} as it is not the Backscratchers app"
    next
  end
  Chef::Log.info "Configuring Backscratchers application '#{application}'"

  # Add the main user to the web server group.
  #
  group 'www-data' do
    action :modify
    members 'ubuntu'
    append true
  end

end
