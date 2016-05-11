#
# Cookbook Name:: topology-truck
# Recipe:: provision  (a phase recipe in a Delivery build-cookbook)
#
# Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0
#
#
# rubocop:disable LineLength
include_recipe 'chef-sugar'

# Setup up some local variable for frequently used values for cleaner code...
# project = node['delivery']['change']['project']
stage = node['delivery']['change']['stage']

# Setup local variables for configuration details in the config.json file...
raw_data = {}
raw_data['topology-truck'] = node['delivery']['config']['topology-truck']

Chef::Log.warn(
  'topology-truck cb: The config.json file has no topology-truck hash so logic is being skipped'
) unless raw_data['topology-truck']
return unless raw_data['topology-truck']

topo_truck_parms = Topo::ConfigParms.new(raw_data.to_hash, stage) if raw_data['topology-truck']

# Decrypt the SSH private key Chef provisioning uses to connect to the
# machine and save the key to disk when the driver is aws
ssh_key = {}
with_server_config do
  ssh_key = encrypted_data_bag_item_for_environment('provisioning-data', 'ssh_key') if topo_truck_parms.driver_type == 'aws'
end
ssh_private_key_path = File.join(node['delivery']['workspace']['cache'], '.ssh')
directory ssh_private_key_path if topo_truck_parms.driver_type == 'aws'
file_name = ssh_key['name'] || 'noFileToSetup'
file File.join(ssh_private_key_path, "#{file_name}.pem") do
  sensitive true
  content ssh_key['private_key']
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
  mode '0600'
  only_if { topo_truck_parms.driver_type == 'aws' }
end

# Load AWS credentials.
include_recipe "#{cookbook_name}::_aws_creds" if topo_truck_parms.driver_type == 'aws'

# Machine options will start with the template for the active driver...
with_machine_options(topo_truck_parms.machine_options)

# Initialize the provisioning driver after loading it..
require 'chef/provisioning/ssh_driver' if topo_truck_parms.driver_type == 'ssh'
require 'chef/provisioning/aws_driver' if topo_truck_parms.driver_type == 'aws'
require 'chef/provisioning/vagrant_driver' if topo_truck_parms.driver_type == 'vagrant'
with_driver topo_truck_parms.driver

if topo_truck_parms.driver_type == 'vagrant'
  vagrant_box 'ubuntu64-12.4' do
    url 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box'
    only_if { topo_truck_parms.driver_type == 'vagrant' }
  end
end

#  The recipe is expecting there to be a list of topologies that need machine
#  for  each stage of the pipeline.  Source of the topology list is determined
#  by the details in the config.json file used to configure this pipeline.
#  When this file contains a 'stage_topology' hash those details are used.
#  Otherwise the topology details in the attribute file is used.

topology_list = []

# Run something in compile phase using delivery chef server
with_server_config do
  Chef::Log.info("Doing stuff like topo truck getting data bags from chef server #{delivery_chef_server[:chef_server_url]}")

  # Retrieve the topology details from data bags in the Chef server...
  topo_truck_parms.topology_list_for_stage(stage).each do |topology_name|
    Chef::Log.warn("This #{topology_name} topology.json was fetched from the Chef server. ")
    topology = Topo::Topology.get_topo(topology_name)

    if topology
      topology_list.push(topology)
    else
      Chef::Log.warn(
        "Unable to find topology #{topology_name} so skipping.")
    end
  end
end

# Setup info so cheffish/chef provisioning uses delivery chef server
with_chef_server(
  delivery_chef_server[:chef_server_url],
  client_name: delivery_chef_server[:options][:client_name],
  signing_key_filename: delivery_chef_server[:options][:signing_key_filename]
# some specific client.rb options can go here, but not ssl_verify_mode
)

# compile-time code here will execute in local chef server context

# arbitrary options to go in client.rb on provisioned nodes
debug_config = "log_level :info \n"\
  'verify_api_cert false'

############################################# old code
# driver_stage_machine_opts = node[project][stage][topo_truck_parms.driver_type]['config']['machine_options']

# Now we are ready to provision the nodes in each of the topologies
topology_list.each do |topology|
  topology_name = topology.name
  # When there are provisioning details in the topology data bag, extract them
  # and load the values into a structure with symbols rather than string hashes
  #     if topology['provisioning'] && topology['provisioning']['ssh']
  #    mach_opts = topology['provisioning']['ssh']['config']['machine_options']
  #    stage_aws_mach_opts['transport_options'] = mach_opts['transport_options']
  #    Chef::Log.warn("*** MACHINE OPTIONS.............    #{mach_opts.inspect}")
  # end

  # Provision each node in the current topology...
  nodes = []
  topology.nodes.each do |node_details|
    # hack...to overcome this message....
    # Cannot move 'buildserver-buildserver-master' from ssh:/var/opt/delivery/workspace/33.33.33.11/ourcompany/
    #  systemoneteam/mvt/master/acceptance/provision/chef/provisioning/ssh to ssh:/var/opt/delivery/workspace/
    #  33.33.33.11/ourcompany/systemoneteam/mvt/master/acceptance/deploy/chef/provisioning/ssh: machine moving
    #  is not supported.  Destroy and recreate.
    nodes << node_details.name

    chef_node node_details.name do
      attribute 'chef_provisioning', {}
      only_if { topo_truck_parms.driver_type == 'ssh' }
    end

    # Prepare a new machine / node for a chef client run...
    machine node_details.name do
      action [:setup]
      converge false
      chef_environment delivery_environment # TODO: logic for topology env

      add_machine_options transport_options: { ip_address: node_details.ssh_host } if node_details.ssh_host
      add_machine_options convergence_options: { ssl_verify_mode: :verify_none }
      add_machine_options convergence_options: { chef_config: debug_config } if debug_config
      add_machine_options bootstrap_options: {
        key_name: ssh_key['name'],
        key_path: ssh_private_key_path
      } if topo_truck_parms.driver_type == 'aws'
    end
  end
  Chef::Log.warn("These Chef nodes are being provisioned for the #{topology_name} topology...")
  Chef::Log.warn(nodes.to_s)
end

ruby_block 'do stuff like delivery truck' do
  block do
    # run stuff using delivery chef server in converge phase
    with_server_config do
      Chef::Log.info(
        'Doing stuff like delivery truck pinning envs with chef server')
    end
  end
end
