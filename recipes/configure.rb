# Configure the system in response to changes.
#
# At the moment there’s nothing here, as there are no changes needed based on the number of servers running / whether there is a load-balancer etc. Each server just needs to serve requests and that’s it.
#

Chef::Log.info("The Backscratchers configure recipe called")
include_recipe 'bs::report'
