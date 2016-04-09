# This recipe configures things that are nice to have on a server while testing / developing the overall Chef setup.
#
# It should not be run on production machines.
#

Chef::Log.info("The Backscratchers dev recipe called")

group 'www-data' do # Make the ubuntu user a member of www-data so we can access everything the server can.
  action :modify
  members 'ubuntu'
  append true
end

file '/home/ubuntu/.bash_aliases' do # Add convenient aliases.
  content %Q{alias lla='ls -lah'}
  owner 'ubuntu'
  group 'ubuntu'
  mode '0600'
end
file '/home/ubuntu/.bash_extras/welcome' do # So anyone logging in knows the dev additions are there.
  content %Q{echo "Backscratchers bash development extras are present (see recipes/dev.rb in the cookbook)"}
  owner 'ubuntu'
  group 'ubuntu'
  mode '0600'
end
# TODO @leo Add any more tweaks that would be nice!
