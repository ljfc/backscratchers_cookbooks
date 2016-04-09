# Stuff to go in other recipes soon...

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
  key 'C43C79AD'
end
package 'logentries'
package 'logentries-daemon'

directory '/etc/le' do
  mode 0750
end
file '/etc/le/config' do
  content %Q{[Main]
user-key = #{secrets['logentries']['user_key']}
pull-server-side-config=False

metrics-interval = 5s
metrics-token = 080e2db3-8f58-4314-84c8-b1087db8ebf1
metrics-cpu = system
metrics-vcpu = core
metrics-mem = system

[BackscratchersRailsLog]
path = /srv/backscratchers/log/#{app['environment']['RAILS_ENV']}.log
destination = BackscratchersStaging/Rails
token = #{secrets['logentries']['rails']}

[BackscratchersCronLog]
path = /srv/backscratchers/log/cron.log
destination = BackscratchersStaging/RailsCron
}
  mode 0640
end

service 'logentries' do
  action [:enable, :restart]
end
