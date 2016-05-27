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

# Local variable for frequently used values for cleaner code...
# project = node['delivery']['change']['project']
stage = node['delivery']['change']['stage']

# Local variables for configuration details in the config.json file...
raw_data = {}
raw_data['topology-truck'] = node['delivery']['config']['topology-truck']
tp_truck_parms = TopologyTruck::ConfigParms.new(raw_data.to_hash)

#  The recipe is expecting there to be a list of topologies that need machine
#  for  each stage of the pipeline.  Source of the topology list is determined
#  by the details in the config.json file used to configure this pipeline.
#  When this file contains a 'stage_topology' hash those details are used.
#  Otherwise the topology details in the attribute file is used.

topology_list = []

with_server_config do
  # Retrieve the topology details from data bags in the Chef server...
  tp_truck_parms.st_topologies(stage).each do |tp_name|
    topology = Topo::Topology.get_topo(tp_name)
    if topology
      topology_list.push(topology)
    else
      Chef::Log.warn(
        "Unable to fetch topology #{tp_name} from the #{delivery_chef_server[:chef_server_url]} so skipping ( #{stage} )."
      )
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

# For AWS driver: Decrypt the SSH private key Chef provisioning uses to connect to the
# AWS machine(image) and save the key to disk
with_server_config do
  include_recipe "#{cookbook_name}::_setup_ssh_for_aws" if tp_truck_parms.any_aws_drivers? == 'aws'
end

# Load AWS credentials.
include_recipe "#{cookbook_name}::_aws_creds" if tp_truck_parms.any_aws_drivers? == 'aws'

# Following code is commented out until vagrant driver support is added.
# if tp_truck_parms.pl_driver_type == 'vagrant'
#  vagrant_box 'ubuntu64-12.4' do
#    url 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box'
#    only_if { tp_truck_parms.pl_driver_type == 'vagrant' }
#  end
# end

# compile-time code here will execute in local chef server context

# arbitrary options to go in client.rb on provisioned nodes
debug_config = "log_level :info \n"\
  'verify_api_cert false'

# Lets use the details in the config.json file to determine the driver
# and machine options that are to be used for this stage.
# Start by using the stage driver which was specified either via a stage{ driver: xxx}
#   or a propagated pipeline{ driver: xxx}.
active_driver = tp_truck_parms.st_driver_type(stage) if tp_truck_parms.has_drivers?
loaded_driver = '_none_'
# TODO: Add logic to handle case in which driver is not specified...
# use_tp_json_driver = true unless tp_truck_parms.has_drivers?

# Machine options will start with the template for the active driver...
with_machine_options(tp_truck_parms.machine_options)

# Now we are ready to provision the nodes in each of the topologies
topology_list.each do |topology|
  tp_name = topology.name

  # When there are provisioning details in the topology data bag, extract them
  # and load the values into a structure with symbols rather than string hashes
  #     if topology['provisioning'] && topology['provisioning']['ssh']
  #    mach_opts = topology['provisioning']['ssh']['config']['machine_options']
  # end

  active_driver = tp_truck_parms.tp_driver_type(tp_name) if tp_truck_parms.tp_has_drivers?(tp_name)

  # Provision each node in the current topology...
  nodes = []
  ssh_key = {}
  ssh_private_key_path = TopologyTruck::ConfigParms.ssh_private_key_path(node['delivery']['workspace']['cache']) # if aws

  topology.nodes.each do |node_details|
    # Keep track of the node names for reporting purposes...
    nodes << node_details.name

    # Initialize the provisioning driver after loading it..
    require 'chef/provisioning/ssh_driver'      if active_driver == 'ssh' && loaded_driver != 'ssh'
    require 'chef/provisioning/aws_driver'      if active_driver == 'aws' && loaded_driver != 'aws'
    # require 'chef/provisioning/vagrant_driver'  if active_driver == 'vagrant'

    with_driver tp_truck_parms.pl_driver unless active_driver == loaded_driver

    loaded_driver = active_driver

    # HACK: to overcome this message....
    # Cannot move 'buildserver-buildserver-master' from ssh:/var/opt/delivery/workspace/33.33.33.11/ourcompany/
    #  systemoneteam/mvt/master/acceptance/provision/chef/provisioning/ssh to ssh:/var/opt/delivery/workspace/
    #  33.33.33.11/ourcompany/systemoneteam/mvt/master/acceptance/deploy/chef/provisioning/ssh: machine moving
    #  is not supported.  Destroy and recreate
    chef_node node_details.name do
      attribute 'chef_provisioning', {}
      only_if { loaded_driver == 'ssh' }
    end
    # HACK: end of hack

    with_server_config do
      # Prepare a new machine / node for a chef client run...
      ssh_key = TopologyTruck::ConfigParms.ssh_key(node)['name'] if loaded_driver == 'aws'
    end

    # Machine options specified in the config.json are used instead of machine options
    # specified in the topology.json
    # tp_machine_options_list = []
    # if tp_truck_parms.tp_level
    #   tp_machine_options_list = tp_truck_parm.topology_specific_machine_options(tp_name)
    # else
    #   # Need code to
    #   tp_machine_options_list = []
    # end

    # Set up the machine for this node...
    machine node_details.name do
      action [:setup]
      converge false
      chef_environment delivery_environment # TODO: logic for topology env

      # Add PIPELINE specified machine options...
      # tp_truck_parm.pipeline_machine_options_list.each do |opt|
      #   add_machine_options option
      # end

      # Add STAGE specified machine options...
      # tp_truck_parm.stage_machine_options_list(stage).each do |opt|
      #   add_machine_options opt
      # end

      # Add TOPOLOGY specified machine options...
      # tp_machine_options_list.each do |opt|
      #   add_machine_options opt
      # end

      # Add NODE specified machine options...
      # node_details.machine_options_list(active_driver).each do |opt|
      #   add_machine_options opt
      # end

      add_machine_options transport_options: { ip_address: node_details.ssh_host } if node_details.ssh_host
      add_machine_options convergence_options: { ssl_verify_mode: :verify_none }
      add_machine_options convergence_options: { chef_config: debug_config } if debug_config
      add_machine_options bootstrap_options: {
        key_name: ssh_key,
        key_path: ssh_private_key_path
      } if loaded_driver == 'aws'
    end
  end
  Chef::Log.warn("These Chef nodes are being provisioned for the #{tp_name} topology...")
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
