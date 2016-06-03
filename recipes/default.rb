#
# Cookbook Name:: topology-truck
# Recipe:: default
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

# rubocop:disable LineLength

# Setup up some local variable for frequently used values for cleaner code...
stage = node['delivery']['change']['stage']

# Setup local variables for configuration details in the config.json file...
raw_data = {}
raw_data['topology-truck'] = node['delivery']['config']['topology-truck']

tp_truck_parms = TopologyTruck::ConfigParms.new(raw_data.to_hash, node)

Chef::Log.warn(
  "topology-truck hash.........  #{raw_data}")
Chef::Log.warn(
  "template.machine_options....  #{tp_truck_parms.machine_options}")
temp = tp_truck_parms.machine_options
Chef::Log.warn(
  "template.machine_option_list....  #{tp_truck_parms.extract_machine_options_list(temp.to_hash)}")
temp = tp_truck_parms.pl_machine_options
Chef::Log.warn(
  "pipeline.machine_option_list....  #{tp_truck_parms.extract_machine_options_list(temp.to_hash)}")

if tp_truck_parms.pl_level?
  Chef::Log.warn(
    "pipline.driver..............  #{tp_truck_parms.pl_driver}")
  Chef::Log.warn(
    "pipeline.driver_type........  #{tp_truck_parms.pl_driver_type}")
  Chef::Log.warn(
    "pipeline.machine_options....  #{tp_truck_parms.pl_machine_options}")
  Chef::Log.warn(
    "pipeline.topologies.........  #{tp_truck_parms.pl_topologies}")
else
  Chef::Log.warn(
    'No PIPELINE level configuration info was specified.')
end

if tp_truck_parms.st_level?
  Chef::Log.warn(
    "stage.driver................  #{tp_truck_parms.st_driver(stage)}")
  Chef::Log.warn(
    "stage.driver_type...........  #{tp_truck_parms.st_driver_type(stage)}")
  Chef::Log.warn(
    "stage.machine_options.......  #{tp_truck_parms.st_machine_options(stage)}")
  Chef::Log.warn(
    "stage.topologies............  #{tp_truck_parms.st_topologies(stage)}")
else
  Chef::Log.warn(
    'No STAGE level configuration info was specified.')
end

if tp_truck_parms.tp_level?
  # Dump out the details for each of the topologies...
  tp_truck_parms.st_topologies(stage).each do |tp_name|
    Chef::Log.warn(
      "topology.driver.............  #{tp_truck_parms.tp_driver(tp_name)}")
    Chef::Log.warn(
      "topology.driver_type........  #{tp_truck_parms.tp_driver_type(tp_name)}")
    Chef::Log.warn(
      "topology.calc_driver_type...  #{tp_truck_parms.tp_calc_driver_type(tp_name)}")
    Chef::Log.warn(
      "topology.machine_options....  #{tp_truck_parms.tp_machine_options(tp_name)}")
    Chef::Log.warn(
      "topology.calc_machine_opts..  #{tp_truck_parms.tp_calc_machine_options(tp_name)}")
  end
else
  Chef::Log.warn(
    'No TOPOLOGY level configuration info was specified.')
end

# Let make sure the driver specified in the config.json file
#  is something we support...
unsupported_driver = tp_truck_parms.pl_driver != 'aws' &&
                     tp_truck_parms.pl_driver != 'ssh'

raise ArgumentError, " '#{tp_truck_parms.pl_driver}' is not a supported Chef provisioning driver at this time. Try using 'ssh' or 'aws' " if unsupported_driver

include_recipe 'topology-truck::_default_build'
include_recipe 'topology-truck::_default_acceptance'
include_recipe 'topology-truck::_default_union'
include_recipe 'topology-truck::_default_rehearsal'
include_recipe 'topology-truck::_default_delivered'
