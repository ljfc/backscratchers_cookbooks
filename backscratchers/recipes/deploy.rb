include_recipe 'deploy'

# AWS OpsWorks recipe to be excuted when deploying the Backscratchers application.
#
# This should be run as an additional recipe on a standard Rails App Server layer.
#
node[:deploy].each do |application, deploy|

  Chef::Log.info "Running backscratchers::deploy for #{application}"
  if (deploy[:application_type] != 'rails') || (application != 'backscratchers')
    Chef::Log.debug("Skipping deploy::rails application #{application} as it is not a Rails app")
    next
  end
  Chef::Log.info "Deploying Backscratchers application '#{application}'"

  begin
    Chef::Log.info "Deployment release path is #{release_path}"
  rescue => e
    Chef::Log.info "There was an error when trying to print the release path"
  end

  deploy deploy[:deploy_to] do
    before_symlink do
      directory "#{release_path}/tmp" do
        mode 0770
      end
    end
  end

end
