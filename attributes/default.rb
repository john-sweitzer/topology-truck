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
end
