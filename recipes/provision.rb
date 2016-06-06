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

# Local variable for cleaner code...
# project = node['delivery']['change']['project']
stage = node['delivery']['change']['stage']

# ...at this point no driver has been loaded...
loaded_driver = '_none_'
active_driver = '_none_'

# Setup info so cheffish/chef provisioning uses Delivery's Chef server
with_chef_server(
  delivery_chef_server[:chef_server_url],
  client_name: delivery_chef_server[:options][:client_name],
  signing_key_filename: delivery_chef_server[:options][:signing_key_filename]
# some specific client.rb options can go here, but not ssl_verify_mode
)

# tp_truck_parms has the content of the config.json for Delivery...
raw_data = {}
raw_data['topology-truck'] = node['delivery']['config']['topology-truck']
tp_truck_parms = TopologyTruck::ConfigParms.new(raw_data.to_hash, node)

# topology_list has the topologies that will be provisioned...
topology_list = []

# topology_list's content comes from the topologies list in the
# config.json when some are specified or from the sample topology JSON
# defined in the cookbook's attributes...

# Use the topology JSON stored in the chef server for the topologies
# in tp_truck_parms... only work with the topologies for the current stage...
with_server_config do
  # Retrieve the topology details from data bags in the Chef server...
  tp_truck_parms.st_topologies(stage).each do |tp_name|
    tp = Topo::Topology.get_topo(tp_name)
    # TODO: When there is not drv/mo details on config.json...only load if there is in the tp.json
    if tp
      topology_list.push(tp) if tp_truck_parms.drivers?
      Chef::Log.warn(
        "There are no driver/machine options details for topology #{tp_name} so it is being skipped."
      ) unless tp_truck_parms.drivers?
    else
      Chef::Log.warn(
        "Unable to fetch topology #{tp_name} from the #{delivery_chef_server[:chef_server_url]} so skipping ( #{stage} )."
      )
    end
  end
end

# When topology_list is still empty use the sample topology JSON
# if topology_list.empty?
#  tp_nm = node[project][stage]['topology']['name']
#  tp = Topo::Topology.new(tp_nm, node.default[project][stage]['topology'].clone)
#  if tp
#    topology_list.push(tp)
#    Chef::Log.warn(
#      "Note: There are no topologies specified for the #{stage} stage so the details in the cook book attributes are being used."
#    )
#  else
#    Chef::Log.warn(
#      "Unable to use the topology json in the attributes for the cook book at node[#{project}][#{stage}][''topology'']"
#    )
#  end
# end

# TODO: any_aws need to include tp.json content when none in config.json
# For AWS driver: Decrypt the SSH private key Chef provisioning uses to connect to the
# AWS machine(image) and save the key to disk
with_server_config do
  include_recipe "#{cookbook_name}::_setup_ssh_for_aws" if tp_truck_parms.any_aws_drivers?
end

# Load AWS credentials.
include_recipe "#{cookbook_name}::_aws_creds" if tp_truck_parms.any_aws_drivers?

# compile-time code here will execute in local chef server context

# arbitrary options to go in client.rb on provisioned nodes
debug_config = "log_level :info \n"\
  'verify_api_cert false'

# tp_truck_parms (details from the config.json file) has the details
# to determine the driver and machine options for this stage.

# Now we are ready to provision the nodes in each of the topologies
topology_list.each do |topology|
  tp_name = topology.name

  # active_driver becomes a driver specified for the current topology in the config.json
  # if any...
  if tp_truck_parms.drivers?
    active_driver = tp_truck_parms.tp_driver_type(tp_name)
    with_machine_options(tp_truck_parms.tp_machine_options(tp_name))
  else
    active_driver = topology.driver_type
    with_machine_options(topology.machine_options)
  end
  # Provision each node in the current topology...
  nodes = []
  ssh_key = {}
  ssh_private_key_path = TopologyTruck::ConfigParms.ssh_private_key_path(node['delivery']['workspace']['cache']) if active_driver == 'aws'

  topology.nodes.each do |node_details|
    # Keep track of the node names for reporting purposes...
    nodes << node_details.name

    # When the nodes has driver/machine option details lets use them
    if nodes.drivers?
      active_driver = nodes.driver_type
      with_machine_options(nodes.machine_options)
    end

    # Initialize the provisioning driver after loading it..
    require 'chef/provisioning/ssh_driver'      if active_driver == 'ssh' && loaded_driver != 'ssh'
    require 'chef/provisioning/aws_driver'      if active_driver == 'aws' && loaded_driver != 'aws'

    with_driver tp_truck_parms.tp_driver(tp_name) unless active_driver == loaded_driver

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

    # Set up the machine for this node...
    machine node_details.name do
      action [:setup]
      converge false
      chef_environment delivery_environment # TODO: logic for topology env

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
