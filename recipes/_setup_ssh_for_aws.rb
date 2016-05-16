#
# Cookbook Name:: topology-truck
# Recipe:: _setup_ssh_to_aws
#
#  Copyright:: Copyright (c) 2016 ThirdWave Insights, LLC
# License:: Apache License, Version 2.0
#

# Decrypt the SSH private key Chef provisioning uses to connect to the
# machine and save the key to disk when the driver is aws
ssh_key = {}
# with_server_config do
  ssh_key = encrypted_data_bag_item_for_environment(
    'provisioning-data',
    'ssh_key'
  )
# end
# ssh_private_key_path = File.join(node['delivery']['workspace']['cache'], '.ssh')
directory TopologyTruck::ConfigParms.ssh_private_key_path(node['delivery']['workspace']['cache'])
file_name = ssh_key['name'] || 'noFileToSetup'
file File.join(ssh_private_key_path, "#{file_name}.pem") do
  sensitive true
  content ssh_key['private_key']
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
  mode '0600'
end
