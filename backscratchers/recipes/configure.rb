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
    #next
  end
  Chef::Log.info "Configuring Backscratchers application '#{application}'"

  # Add the main user to the web server group.
  #
  group 'www-data' do
    action :modify
    members 'ubuntu'
    append true
  end

  # Create various secret files.
  # TODO @leo Figure out how to include the other Xero config files.
  #
  template "#{deploy[:deploy_to]}/shared/secrets.yml" do
    source "secrets.yml.erb"
    mode 0660
    group deploy[:group]
    if platform?('ubuntu')
      owner 'www-data'
    elsif platform?('amazon')
      owner 'apache'
    end

    variables(:vars => deploy.fetch(:secrets), :environment => deploy[:rails_env])

    only_if do
      deploy[:secrets].present? && File.directory?("#{deploy[:deploy_to]}/shared/")
    end
  end
  #[:secrets,
  # :s3_credentials,
  # :insightly,
  # :xero
  #].each do |key|
  #  template "#{deploy[:deploy_to]}/shared/#{key.to_s}.yml" do
  #    source "#{key.to_s}.yml"
  #    mode 0660
  #    group deploy[:group]
  #    if platform?('ubuntu')
  #      owner 'www-data'
  #    elsif platform?('amazon')
  #      owner 'apache'
  #    end

  #    variables { vars: deploy.fetch(key), environment: deploy[:rails_env] }

  #    only_if do
  #      deploy[key].present? && File.directory?("#{deploy[:deploy_to]}/shared/")
  #    end
  #  end
  #end

end
