app = search('aws_opsworks_app', 'shortname:backscratchers').first
db = search('aws_opsworks_rds_db_instance').first

application '/srv/backscratchers' do
  Chef::Log.info("Deploying The Backscratchers")
  provider :deploy_revision

  ruby do
    provider :ruby_build
    version '2.1.3'
  end

  Chef::Log.info("Installing with git from #{app['app_source']['url']}")
  git do
    repository app['app_source']['url']
    deploy_key app['app_source']['ssh_key']
  end

  Chef::Log.info("Bundling gems")
  bundle_install do
    deployment true
    without %w{development test}
  end

  Chef::Log.info("Deploying rails app...")
  rails do
    Chef::Log.info("\t...using database #{db['db_instance_identifier']} at #{db['address']}")
    database do
      adapter 'mysql2'
      host db['address']
      username db['db_user']
      password db['db_password']
      database db['db_instance_identifier']
    end
  end

  Chef::Log.info("Running unicorn")
  unicorn do
    port 8000
  end

end
