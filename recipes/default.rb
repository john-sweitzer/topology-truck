#
# Cookbook Name:: topology-truck
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
# rubocop:disable LineLength
# Setup up some local variable for frequently used values for cleaner code...
# project = node['delivery']['change']['project']

stage = node['delivery']['change']['stage']

# Setup local variables for configuration details in the config.json file...
raw_data = {}
raw_data['topology-truck'] = node['delivery']['config']['topology-truck']

Chef::Log.warn(
  'topology-truck cb: No topology-truck hash so logic is skipped'
) unless raw_data['topology-truck']

return unless raw_data['topology-truck']

topo_truck_parms = TopologyTruck::ConfigParms.new(
  raw_data.to_hash, stage
) if raw_data['topology-truck']

Chef::Log.warn(
  "topology-truck hash.......  #{raw_data}")
Chef::Log.warn(
  "template.machine_options..  #{topo_truck_parms.machine_options}")

if topo_truck_parms.pl_level?
  Chef::Log.warn(
    "pipline.driver............  #{topo_truck_parms.pl_driver}")
  Chef::Log.warn(
    "pipeline.driver_type......  #{topo_truck_parms.pl_driver_type}")
  Chef::Log.warn(
    "pipeline.machine_options..  #{topo_truck_parms.pl_machine_options}")
  Chef::Log.warn(
    "pipeline.topologies.......  #{topo_truck_parms.pl_topologies}")
else
  Chef::Log.warn(
    'No PIPELINE level configuration info was specified.')
end

if topo_truck_parms.st_level?
  Chef::Log.warn(
    "stage.driver..............  #{topo_truck_parms.st_driver(stage)}")
  Chef::Log.warn(
    "stage.driver_type.........  #{topo_truck_parms.st_driver_type(stage)}")
  Chef::Log.warn(
    "stage.machine_options.....  #{topo_truck_parms.st_machine_options(stage)}")
  Chef::Log.warn(
    "stage.topologies..........  #{topo_truck_parms.st_topologies(stage)}")
else
  Chef::Log.warn(
    'No STAGE level configuration info was specified.')
end

if topo_truck_parms.tp_level?
  Chef::Log.warn(
    "topology.driver..............  #{topo_truck_parms.tp_driver(stage)}")
  Chef::Log.warn(
    "topology.driver_type.........  #{topo_truck_parms.tp_driver_type(stage)}")
  Chef::Log.warn(
    "topology.machine_options.....  #{topo_truck_parms.tp_machine_options(stage)}")
  Chef::Log.warn(
    "topology.topologies..........  #{topo_truck_parms.tp_topologies(stage)}")
else
  Chef::Log.warn(
    'No TOPOLOGY level configuration info was specified.')
end

# Let make sure the driver specified in the config.json file
#  is something we support...
unsupported_driver = topo_truck_parms.pl_driver != 'aws' &&
                     topo_truck_parms.pl_driver != 'ssh'

raise ArgumentError, " '#{topo_truck_parms.pl_driver}' is not a supported Chef provisioning driver at this time. Try using 'ssh' or 'aws' " if unsupported_driver

include_recipe 'topology-truck::_default_acceptance'
include_recipe 'topology-truck::_default_union'
include_recipe 'topology-truck::_default_rehearsal'
include_recipe 'topology-truck::_default_delivered'
