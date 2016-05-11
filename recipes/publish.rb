#
# Cookbook Name:: topology-truck
# Recipe:: publish
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

topo_change = TopologyTruck::Change.new(change)
knife_args = "--config #{delivery_knife_rb}"

topo_change.changed_topologies.each do |topology_file, topology|
  topo_name = topology.name
  path = File.join(node['delivery']['workspace']['repo'], topology_file)
  execute "publish topology #{topo_name} to Chef Server" do
    cwd node['delivery']['workspace']['chef']
    command "knife topo import \"#{path}\" #{knife_args} && " \
      "knife topo create #{topo_name} --yes #{knife_args}"
  end
end
