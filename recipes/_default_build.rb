#
# Cookbook Name:: topology-truck
# Recipe:: _default_build
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0

if node['delivery']['change']['stage'] == 'build'
  chef_gem 'knife-topo' do
    compile_time false
  end

  # The chef directory is owned by root, so we have to pre-create the
  # data_bags dir so we can import the topologies
  directory File.join(node['delivery']['workspace']['chef'], 'data_bags') do
    owner node['delivery_builder']['build_user']
  end
end
