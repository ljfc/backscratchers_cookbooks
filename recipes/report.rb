if node.has_key?('report') && node['report'] == true

  Chef::Log.info("*** Backscratchers Report ***")

  def bs_report(data)
    if data.respond_to?(:'any?') && data.any?
      Chef::Log.info("\t\t[")
      data.each do |item|
        if item.respond_to?(:'any?') && item.any?
          Chef::Log.info("\t\t\t[")
          item.each do |sub_item|
            Chef::Log.info("\t\t\t\t#{sub_item.inspect}")
          end
          Chef::Log.info("\t\t\t]")
        else
          Chef::Log.info("\t\t\t#{item.inspect}")
        end
      end
      Chef::Log.info("\t\t]")
    else
      Chef::Log.info("\t\t#{data.inspect}")
    end
  end

  Chef::Log.info("Node contents:")
  node.keys.each do |key|
    Chef::Log.info("\t#{key}")
    bs_report node[key]
  end

  Chef::Log.info("Data bag contents:")
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
    Chef::Log.info("\t#{index}")
    bs_report search(index.to_s)
  end

  Chef::Log.info("*** Report complete ***")

else
  Chef::Log.info("*** Skipping Backscratchers report as it was not requested ***")
end
