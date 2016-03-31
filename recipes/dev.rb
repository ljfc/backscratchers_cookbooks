Chef::Log.info("The Backscratchers dev recipe called")

# This recipe configures things that are nice to have on a server while testing / developing the overall Chef setup.
#
# It should not be run on production machines.
#
app = search('aws_opsworks_app', 'shortname:backscratchers').first
db = search('aws_opsworks_rds_db_instance').first


Chef::Log.info("Configure the user")
group 'www-data' do
  action :modify
  members 'ubuntu'
  append true
end

Chef::Log.info("Configure bash")
file '/home/ubuntu/.bash_aliases' do # Add convenient aliases.
  content %Q{alias lla='ls -lah'}
  owner 'ubuntu'
  group 'ubuntu'
  mode '0600'
end
directory '/home/ubuntu/.bash_development_extras' do # Add dir for bash extras.
  owner 'ubuntu'
  group 'ubuntu'
  mode '0700'
end
file '/home/ubuntu/.bash_profile' do # Add .bash_profile.
  content %Q{echo "Backscratchers bash development extras are present (see recipes/dev.rb in the cookbook)"
[[ -r ~/.bash_development_extras ]] && . ~/.bash_development_extras/*
[[ -r ~/.bashrc ]] && . ~/.bashrc
}
  owner 'ubuntu'
  group 'ubuntu'
  mode '0600'
end

Chef::Log.info("Install chruby")
execute 'download_chruby' do
  cwd '/home/ubuntu'
  command %Q{wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz && tar -xzvf chruby-0.3.9.tar.gz}
end
execute 'install_chruby' do
  cwd '/home/ubuntu/chruby-0.3.9'
  command %Q{make install}
end
file '/home/ubuntu/.bash_development_extras/chruby' do
  content %Q{source /usr/local/share/chruby/chruby.sh
RUBIES+=(
  /opt/ruby_build/builds/srv/backscratchers
)
source /usr/local/share/chruby/auto.sh

export RAILS_ENV=#{app['environment']['RAILS_ENV']}
}
  owner 'ubuntu'
  group 'ubuntu'
  mode '0600'
end
