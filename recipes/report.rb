Chef::Log.info("*** Backscratchers Report ***")

data_bag_indices = [:aws_opsworks_app,
                    :aws_opsworks_command,
                    :aws_opsworks_ecs_cluster,
                    :aws_opsworks_elastic_load_balancer,
                    :aws_opsworks_instance,
                    :aws_opsworks_layer,
                    :aws_opsworks_rds_db_instance,
                    :aws_opsworks_stack,
                    :aws_opsworks_user]

data_bag_indices.each do |index|
  data = search(index.to_s)
  Chef::Log.info("\t#{index}")
  Chef::Log.info("#{data.inspect}")
end

Chef::Log.info("*** Report complete ***")
