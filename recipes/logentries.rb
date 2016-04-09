# Stuff to go in other recipes soon...


# Setup
Chef::Log.info("Logentries setup")
# Add the Logentries APT repository.
apt_repository 'logentries' do
  uri 'http://rep.logentries.com/'
  distribution 'trusty'
  components ['main']

  keyserver 'pgp.mit.edu'
  key 'C43C79AD'
end
package 'logentries'
package 'logentries-daemon'

# Configure
Chef::Log.info("Configure Logentries")
execute '/var/log/whatever.log' do
  command 'sudo le follow "/var/log/whatever.log"'
end
file '/etc/le/config' do
  content %Q{[Main]
user-key = xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx
pull-server-side-config=False

[YourLogName_OR_YourAppName]
path = /path/to/logfile
destination = LogSet/LogName
token =
}
end
