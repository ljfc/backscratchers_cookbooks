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

  # Adjust permissions on directories that need to be writeable by the webapp/server.
  # TODO @leo Should this go somewhere else? Maybe not. Doesn't seem like it should be needed per-deploy...
  #
  directory "#{deploy[:deploy_to]}/shared/log" do
    mode 0770
  end


  # Create various secret files.
  # TODO @leo Figure out how to include the other Xero config files.
  #
  Chef::Log.info "Processing Backscratchers templates"
  Chef::Log.info "deploy[:secrets].present? #{deploy[:secrets].present?}"
  Chef::Log.info "File.directory?(\"\#{deploy[:deploy_to]}/shared/\") #{File.directory?("#{deploy[:deploy_to]}/shared/")}"
  Chef::Log.info "platform?('ubuntu') #{platform?('ubuntu')}"
  Chef::Log.info "variables #{{:vars => deploy.fetch(:secrets), :environment => deploy[:rails_env]}.inspect}"

  #template "#{deploy[:deploy_to]}/shared/config/secrets.yml" do
  #  Chef::Log.info "Processing template secrets.yml"
  #  source "secrets.yml.erb"
  #  mode 0660
  #  user deploy[:user]
  #  group deploy[:group]

  #  variables(:vars => deploy.fetch(:secrets), :environment => deploy[:rails_env])

  #  only_if do
  #    deploy[:secrets].present? && File.directory?("#{deploy[:deploy_to]}/shared/")
  #  end
  #end

  [:s3_credentials,
   :insightly,
   :xero,
   :secrets
  ].each do |key|
    template "#{deploy[:deploy_to]}/shared/config/#{key.to_s}.yml" do
      Chef::Log.info "Processing template #{key.to_s}.yml"
      source "#{key.to_s}.yml.erb"
      mode 0660
      user deploy[:user]
      group deploy[:group]

      variables(:vars => deploy.fetch(key), :environment => deploy[:rails_env])

      only_if do
        deploy[key].present? && File.directory?("#{deploy[:deploy_to]}/shared/")
      end
    end
  end

end