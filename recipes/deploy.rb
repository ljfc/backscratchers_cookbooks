Chef::Log.info("The Backscratchers deploy recipe called")

# Deploy the site.
#
# The recommended approach is to use deploy_revision, as it is idempotent if the same version of the code is deployed multiple times.
#
deploy_revision 'backscratchers' do 

  repository 'https://github.com/ljfc/backscratchers'
  revision 'checking'

  environment 'RAILS_ENV' => 'pre_staging'

  migrate false # TODO @leo Figure out when this ought to be true. Could it cause an issue if run on multiple servers simultaneously? In which case maybe it should be managed separately from deployment.
  # migration_command # TODO @leo What should this be? Is the default okay for Rails?
  
  before_migrate do # TODO @leo Figure out if database.yml needs creating here, and then what else needs creating.
    Chef::Log.info("Running before_migrate callback")
  end

  rollback_on_error true # TODO @leo Test that this works.

  #symlink_before_migrate 'config/database.yml' => 'config/database.yml' # Additional files to symlink before running migrations.
  #purge_before_symlink # Directories to purge. Default is the same as create_dirs... below.
  #create_dirs_before_symlink # Directories to create before running symlink. Default tmp/ public/ config/
  #symlinks # Additional files to symlink before restarting following deployment. Default system => public/system, pids => tmp/pids, log => log

  user 'ubuntu'
  group 'www-data' # So that web-related users can access the application. TODO @leo Is this best practice? Should the web application user have access to all the site files?

  notifies :restart, 'service[nginx]', :delayed
end

# Restart (or start) NGINX.
#Chef::Log.info("NGINX deployment")
#service 'nginx' do
#  action :restart
#end
