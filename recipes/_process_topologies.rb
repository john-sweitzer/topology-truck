#
# Cookbook Name:: topology-truck
# Recipe:: _process_topologies "process" (that is, provision or deploys) the
#   nodes for the topologies specified in the Chef Delivery's config.json file.
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

# ...at this point no drivers have been loaded...
loaded_driver = '_none_'
active_driver = '_none_'
setup_aws = false

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

# topology_list has the topologies that will be processed by this recipe
# ... its content are topology objects created from the topology.json file
# in the Chef server.
topology_list = []

# The topologies specified in the config.json require corresponding
# topology.json (ala knife-topo plugin) files in the Chef server.
# Only topologies for the current stage that are provisionable
# (i.e., have driver and machine options) are added to topology_list.
with_server_config do
  tp_truck_parms.st_topologies(stage).each do |tp_name|
    # Retrieve the json from the 'topology' data bag in the Chef server...
    tp = Topo::Topology.get_topo(tp_name)
    if tp
      if tp_truck_parms.provisionable?(tp_name)
        topology_list.push(tp)
        setup_aws = tp.aws_driver?
      else
        # Only add this topology if it has driver/machine option details
        topology_list.push(tp) if topology.provisionable?
        Chef::Log.warn(
          "There are no driver/machine options details for topology #{tp_name} so it is being skipped."
        ) unless topology.provisionable?
      end
    else
      Chef::Log.warn(
        "Unable to fetch topology #{tp_name} from the #{delivery_chef_server[:chef_server_url]} so skipping ( #{stage} )."
      )
    end
  end
end

# For AWS driver: Decrypt the SSH private key Chef provisioning uses to connect to the
# AWS machine(image) and save the key to disk
setup_aws ||= tp_truck_parms.any_aws_drivers?
with_server_config do
  include_recipe "#{cookbook_name}::_setup_ssh_for_aws" if setup_aws
end
# Load AWS credentials.
include_recipe "#{cookbook_name}::_aws_creds" if setup_aws

# compile-time code here will execute in local chef server context

# arbitrary options to go in client.rb on provisioned nodes
debug_config = "log_level :info \n"\
  'verify_api_cert false'

# Now we are ready to process the nodes for the topologies
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

    # Ponder:
    #   Are we looking for machine options for the "active_driver" or
    #   are we looking for machine options specific to this node (for example, mongolabs)

    # When the current node has machine option fragments for the active driver
    # we need to apply them to the machine options...
    nd_mo_frgs_list = []
    if topology.driver(node_details.name, active_driver)
      nd_mo_frgs = topology.node_machine_options(node_details.name)
      nd_mo_frgs_list = tp_truck_parms.aws_machine_options_list(nd_mo_frgs) if active_driver == 'aws'
      nd_mo_frgs_list = tp_truck_parms.ssh_machine_options_list(nd_mo_frgs) if active_driver == 'ssh'
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
      nd_mo_frgs_list.each do |fragment|
        add_machine_options fragment
      end

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
