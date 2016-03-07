include_recipe 'deploy'

# AWS OpsWorks recipe to be excuted when deploying the Backscratchers application.
#
# This should be run as an additional recipe on a standard Rails App Server layer.
#
node[:deploy].each do |application, deploy|

  Chef::Log.info "Running backscratchers::deploy for #{application}"
  deploy.each do |key, value|
    Chef::Log.info "     #{key}: #{value}"
  end
  Chef::Log.info application.inspect

  if (deploy[:application_type] != 'rails') || (application != 'backscratchers')
    Chef::Log.debug("Skipping deploy::rails application #{application} as it is not a Rails app")
    next
  end
  Chef::Log.info "Deploying Backscratchers application '#{application}'"

  #deploy deploy[:deploy_to] do
  #  begin
  #    Chef::Log.info "Deployment release path is #{release_path}"
  #  rescue => e
  #    Chef::Log.info "There was an error when trying to print the release path"
  #  end
  #  before_symlink do
  #    directory "#{release_path}/tmp" do
  #      mode 0770
  #    end
  #  end
  #end

end
