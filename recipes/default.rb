#
# Cookbook Name:: topology-truck
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.



# Setup up some local variable for frequently used values for cleaner code...
project = node['delivery']['change']['project']
stage = node['delivery']['change']['stage']



# Setup local variables for configuration details in the config.json file...
raw_data = {}
raw_data['topology-truck'] = node['delivery']['config']['topology-truck']

topo_truck_parms = Topo::ConfigurationParameter.new(raw_data.to_hash,stage) if raw_data['topology-truck']

Chef::Log.warn("driver:                      #{topo_truck_parms.driver()}")

unsupportedDriver = topo_truck_parms.driver() != 'aws' && topo_truck_parms.driver() != 'ssh'

Chef::Log.warn("unsupporteddriver:                      #{unsupportedDriver}")
raise ArgumentError, " '#{topo_truck_parms.driver()}' is not a supported Chef provisioning driver at this time. Try using 'ssh' or 'aws' " if unsupportedDriver



include_recipe 'topology-truck::_default_acceptance'
include_recipe 'topology-truck::_default_union'
include_recipe 'topology-truck::_default_rehearsal'
include_recipe 'topology-truck::_default_delivered'
