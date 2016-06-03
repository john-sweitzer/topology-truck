#
# Cookbook Name:: build-cookbook
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

project = node['delivery']['change']['project']

# arbitrary options to go in client.rb on provisioned nodes
debug_config = "log_level :info \n"\
'verify_api_cert false'

%w(acceptance union rehearsal delivered).each do |stage|
  #
  default[project][stage]['ssh']['config'] = {
    machine_options:  {
      transport_options: {
        'ip_address' => '10.0.1.2',
        'username' => 'vagrant',
        'ssh_options' => {
          'password' => 'vagrant'
        }
      },
      convergence_options: {
        ssl_verify_mode: :verify_none,
        chef_config: debug_config
      }
    }
  }
  #

  #
  default[project][stage]['topology'] =
    {
      name: "#{stage}-#{project}",
      version: '_not_used_',
      buildstamp: '_not_used_',
      buildid: '_not_used_',
      strategy: 'direct_to_node',
      chef_environment: 'tp_1n_z',
      tags: [],
      nodes: [
        {
          'name' => "#{stage}-#{project}",
          'node_type' => 'SingleNode',
          'tags' => [],
          'normal' => {
            'topo' => {
              'node_type' => 'SingleNode',
              'name' => "#{stage}-#{project}"
            },
            'yum' => {
              'version' => '3.2.20',
              'newattr' => 'tracker'
            }
          },
          'run_list' => ['recipe[yum::default]']
        }
      ],
      'services' => []
    }
end
