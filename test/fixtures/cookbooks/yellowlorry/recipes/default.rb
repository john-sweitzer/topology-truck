#
# Cookbook Name:: yellowlorry
# Recipe:: default
#
# Copyright (c) 2016 ThirdWave Insights, LLC, All Rights Reserved.

info = {
  name: node.name,
  environment: node.chef_environment,
  info: node['topology-truck']['testinfo']
}

file '/tmp/yellowlorry' do
  content info.inspect
end
