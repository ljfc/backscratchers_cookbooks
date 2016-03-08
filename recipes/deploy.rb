app = search('aws_opsworks_app', 'shortname:backscratchers').first
db = search('aws_opsworks_rds_db_instance').first

application '/backscratchers' do

  ruby do
    provider :ruby_build
    version '2.1.3'
  end

  git do
    repository app['app_source']['url']
    deploy_key app['app_source']['ssh_key']
  end

  bundle_install do
    deployment true
    without %w{development test}
  end

  rails do
    database do
      adapter 'mysql2'
      host db['address']
      username db['db_user']
      password db['db_password']
      database db['db_instance_identifier']
    end
  end

  unicorn do
    port 8000
  end

end
