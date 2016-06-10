#
# Cookbook Name:: topology-truck
# Recipe:: deploy is a stage recipe for Chef's Delivery product that call
#           _process_topologies to deploy the nodes for the topologies
#           specified in a config.json file.
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0
#

include_recipe 'topology-truck::_process_topologies'
