#
# Cookbook Name:: topology-truck
# Recipe:: _default_ssh
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0
# rubocop:disable LineLength
# Use these local variable in the rest of the recipe to make the code cleaner...

# Setup ssh provisioning  if it is needed

raw_data = {}
raw_data['topology-truck'] = node['delivery']['config']['topology-truck']

config = TopologyTruck::ConfigParms.new(raw_data.to_hash) if raw_data['topology-truck']

deliver_using_ssh = config.pl_driver_type == 'ssh' if config

chef_gem 'chef-provisioning-ssh' do
  only_if { deliver_using_ssh }
end

workspace = node['delivery']['workspace']

directory "#{workspace['root']}/chef/provisioning/ssh" do
  mode 00755
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
  recursive true
  action :create
  only_if { deliver_using_ssh }
end
