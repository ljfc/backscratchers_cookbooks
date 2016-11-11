# Set up logging to the Logentries service.
#
# The system will work just fine without this, so if you want it you have to call it explicitly.
#

Chef::Log.info("The Backscratchers logentries recipe called")

instance = search('aws_opsworks_instance', 'self:true').first
app = search('aws_opsworks_app', 'shortname:backscratchers').first
db = search('aws_opsworks_rds_db_instance').first
secrets = node['secrets']
if node.has_key? 'rds' # Override the OpsWorks RDS info, so we are not always stuck with the AWS RDS info provided by default.
  db = node['rds']
end

apt_repository 'logentries' do # Add the Logentries APT repository.
  uri 'http://rep.logentries.com/'
  distribution 'trusty'
  components ['main']

  keyserver 'pgp.mit.edu'
  key 'A5270289C43C79AD'
end
package 'logentries'
package 'logentries-daemon'

directory '/etc/le' do
  mode 0750
end
template '/etc/le/config' do
  source 'logentries.erb'
  mode 0640
  variables(environment: app['environment']['RAILS_ENV'], logentries: secrets['logentries'])
end

service 'logentries' do
  action [:enable, :restart]
end
