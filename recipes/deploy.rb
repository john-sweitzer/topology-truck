#
# Cookbook Name:: topology-truck
# Recipe:: deploy
#
#  Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0
#
# rubocop:disable LineLength

include_recipe 'chef-sugar'

# Use these local variable in the rest of the recipe.
# project = node['delivery']['change']['project']
stage = node['delivery']['change']['stage']

# Setup local variables for configuration details
# from the config.json file...

raw_data = {}
raw_data['topology-truck'] = node['delivery']['config']['topology-truck']
tp_truck_parms = TopologyTruck::ConfigParms.new(raw_data.to_hash, node)

# Decrypt the SSH private key Chef provisioning uses to connect to the
# machine and save the key to disk when the driver is aws
with_server_config do
  include_recipe "#{cookbook_name}::_setup_ssh_for_aws" if tp_truck_parms.pl_driver_type == 'aws'
end

# Load AWS credentials.
include_recipe "#{cookbook_name}::_aws_creds" if tp_truck_parms.pl_driver_type == 'aws'

# Machine options will start with the template for the active driver...
with_machine_options(tp_truck_parms.machine_options)

# Initialize the provisioning driver after loading it..
require 'chef/provisioning/ssh_driver' if tp_truck_parms.pl_driver_type == 'ssh'
require 'chef/provisioning/aws_driver' if tp_truck_parms.pl_driver_type == 'aws'
# require 'chef/provisioning/vagrant_driver' if tp_truck_parms.pl_driver_type == 'vagrant'

with_driver tp_truck_parms.pl_driver
# Following code is commented out until vagrant driver support is added.
# if tp_truck_parms.pl_driver_type == 'vagrant'
#  vagrant_box 'ubuntu64-12.4' do
#    url 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box'
#    only_if { tp_truck_parms.pl_driver_type == 'vagrant' }
#  end
# end

#  The recipe is expecting there to be a list of topologies that need machine
#  for  each stage of the pipeline.  Source of the topology list is determined
#  by the details in the config.json file used to configure this pipeline.
#  When this file contains a 'stage_topology' hash those details are used.
#  Otherwise the topology details in the attribute file is used.

topology_list = []

# Run something in compile phase using delivery chef server
with_server_config do
  # Retrieve the topology details from data bags in the Chef server...
  tp_truck_parms.st_topologies(stage).each do |topology_name|
    topology = Topo::Topology.get_topo(topology_name)
    if topology
      topology_list.push(topology)
    else
      Chef::Log.warn(
        "Unable to fetch topology #{topology_name} from chef server #{delivery_chef_server[:chef_server_url]} so skipping (deploy).")
    end
  end
end

# Setup info so cheffish/chef provisioning uses delivery chef server
with_chef_server(
  delivery_chef_server[:chef_server_url],
  client_name: delivery_chef_server[:options][:client_name],
  signing_key_filename: delivery_chef_server[:options][:signing_key_filename]
# some specific client.rb options can go here, but not ssl_verify_mod
)

# compile-time code here will execute in local chef server context

# arbitrary options to go in client.rb on provisioned nodes
debug_config = "log_level :info \n"\
  'verify_api_cert false'

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
  nodes = []
  ssh_private_key_path = TopologyTruck::ConfigParms.ssh_private_key_path(node['delivery']['workspace']['cache']) # if aws
  # Provision each node in the current topology...
  topology.nodes.each do |node_details|
    nodes << node_details.name

    # hack...to overcome this message....
    # Cannot move 'buildserver-buildserver-master' from ssh:/var/opt/delivery/workspace/33.33.33.11/ourcompany/
    #  systemoneteam/mvt/master/acceptance/provision/chef/provisioning/ssh to ssh:/var/opt/delivery/workspace/
    #  33.33.33.11/ourcompany/systemoneteam/mvt/master/acceptance/deploy/chef/provisioning/ssh: machine moving
    #  is not supported.  Destroy and recreate.

    chef_node node_details.name do
      attribute 'chef_provisioning', {}
      only_if { tp_truck_parms.pl_driver_type == 'ssh' }
    end

    # Prepare a new machine / node for a chef client run...
    include_ip_address = node_details.ssh_host && tp_truck_parms.pl_driver_type == 'ssh'
    with_server_config do
      machine node_details.name do
        action [:converge]
        chef_environment delivery_environment # TODO: logic for topology environments
        attributes node_details.attributes if node_details.attributes
        converge true
        run_list node_details.run_list if node_details.run_list

        add_machine_options transport_options: { ip_address: node_details.ssh_host } if include_ip_address
        add_machine_options convergence_options: { ssl_verify_mode: :verify_none }
        add_machine_options convergence_options: { chef_config: debug_config } if debug_config
        add_machine_options bootstrap_options: {
          key_name: TopologyTruck::ConfigParms.ssh_key(node)['name'],
          key_path: ssh_private_key_path
        } if tp_truck_parms.pl_driver_type == 'aws'
        #     machine_options(
        #       transport_options: {
        #         'ip_address' => node_details.ssh_host,
        #         'username' => 'vagrant',
        #         'ssh_options' => {
        #           'password' => 'vagrant'
        #         }
        #       },
        #       convergence_options: {
        #         ssl_verify_mode: :verify_none,
        #         chef_config: debug_config
        #       }
        #     )
      end
    end
  end
  Chef::Log.warn("These Chef nodes are being deployed for the #{topology_name} topology...")
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
