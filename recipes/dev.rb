Chef::Log.info("The Backscratchers dev recipe called")

# This recipe configures things that are nice to have on a server while testing / developing the overall Chef setup.
#
# It should not be run on production machines.


Chef::Log.info("Configure bash")
file '/ubuntu/.bash_aliases' do # Add convenient aliases.
  content %Q{alias lla='ls -lah'}
  owner 'ubuntu'
  group 'ubuntu'
  mode '0600'
end
directory '/ubuntu/.bash_development_extras' do # Add dir for bash extras.
  owner 'ubuntu'
  group 'ubuntu'
  mode '0700'
end
file '/ubuntu/.bash_profile' do # Add .bash_profile.
  content %Q{echo "Backscratchers bash development extras are present (see recipes/dev.rb in the cookbook)"
[[ -r ~/.bash_development_extras ]] && . ~/.bash_dev_tweaks/*
[[ -r ~/.bashrc ]] && . ~/.bashrc
}
  owner 'ubuntu'
  group 'ubuntu'
  mode '0600'
end

Chef::Log.info("Install chruby")
execute 'download_chruby' do
  cwd '/ubuntu'
  command %Q{wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz && tar -xzvf chruby-0.3.9.tar.gz}
end
execute 'install_chruby' do
  cwd '/ubuntu/chruby-0.3.9'
  command %Q{make install}
end
file '/ubuntu/.bash_development_extras/chruby' do
  content %Q{source /usr/local/share/chruby/chruby.sh
RUBIES+=(
  /opt/ruby_build/builds/srv/backscratchers
)
}
  owner 'ubuntu'
  group 'ubuntu'
  mode '0600'
end
