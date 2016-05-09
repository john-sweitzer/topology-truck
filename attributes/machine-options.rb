






# Machine options for aws across the pipeline
default['topology-truck']['pipeline']['aws']['key_name']                = ENV['USER']
default['topology-truck']['pipeline']['aws']['ssh_username']            = nil
default['topology-truck']['pipeline']['aws']['security_group_ids']      = nil
default['topology-truck']['pipeline']['aws']['image_id']                = nil
default['topology-truck']['pipeline']['aws']['subnet_id']               = nil
default['topology-truck']['pipeline']['aws']['bootstrap_proxy']         = ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
default['topology-truck']['pipeline']['aws']['chef_config']             = nil
default['topology-truck']['pipeline']['aws']['chef_version']            = nil
default['topology-truck']['pipeline']['aws']['use_private_ip_for_ssh']  = false

# Machine options for ssh across the pipeline
default['topology-truck']['pipeline']['ssh']['key_file']                = nil
default['topology-truck']['pipeline']['ssh']['prefix']                  = nil
default['topology-truck']['pipeline']['ssh']['ssh_username']            = nil
default['topology-truck']['pipeline']['ssh']['bootstrap_proxy']         = ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
default['topology-truck']['pipeline']['ssh']['chef_config']             = nil
default['topology-truck']['pipeline']['ssh']['chef_version']            = nil
default['topology-truck']['pipeline']['ssh']['use_private_ip_for_ssh']  = false

# Machine options for vagrant across the pipeline
default['topology-truck']['pipeline']['vagrant']['key_file']            = nil
default['topology-truck']['pipeline']['vagrant']['prefix']              = nil
default['topology-truck']['pipeline']['vagrant']['ssh_username']        = nil
default['topology-truck']['pipeline']['vagrant']['vm_box']              = nil
default['topology-truck']['pipeline']['Vagrant']['image_url']           = nil
default['topology-truck']['pipeline']['Vagrant']['vm_memory']           = nil
default['topology-truck']['pipeline']['Vagrant']['vm_cpus']             = nil
default['topology-truck']['pipeline']['vagrant']['network']             = nil
default['topology-truck']['pipeline']['vagrant']['key_file']            = nil
default['topology-truck']['pipeline']['vagrant']['chef_config']         = nil
default['topology-truck']['pipeline']['vagrant']['chef_version']        = nil





# AWS machine options to used during the acceptance stage
default['topology-truck']['acceptance']['aws']['key_name']                = ENV['USER']
default['topology-truck']['acceptance']['aws']['ssh_username']            = nil
default['topology-truck']['acceptance']['aws']['security_group_ids']      = nil
default['topology-truck']['acceptance']['aws']['image_id']                = nil
default['topology-truck']['acceptance']['aws']['subnet_id']               = nil
default['topology-truck']['acceptance']['aws']['bootstrap_proxy']         = ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
default['topology-truck']['acceptance']['aws']['chef_config']             = nil
default['topology-truck']['acceptance']['aws']['chef_version']            = nil
default['topology-truck']['acceptance']['aws']['use_private_ip_for_ssh']  = false

# SSH machine options to used during the acceptance stage
default['topology-truck']['acceptance']['ssh']['key_file']                = nil
default['topology-truck']['acceptance']['ssh']['prefix']                  = nil
default['topology-truck']['acceptance']['ssh']['ssh_username']            = nil
default['topology-truck']['acceptance']['ssh']['bootstrap_proxy']         = ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
default['topology-truck']['acceptance']['ssh']['chef_config']             = nil
default['topology-truck']['acceptance']['ssh']['chef_version']            = nil
default['topology-truck']['acceptance']['ssh']['use_private_ip_for_ssh']  = false

# VAGRANT machine options to used during the acceptance stage
default['topology-truck']['acceptance']['vagrant']['key_file']            = nil
default['topology-truck']['acceptance']['vagrant']['prefix']              = nil
default['topology-truck']['acceptance']['vagrant']['ssh_username']        = nil
default['topology-truck']['acceptance']['vagrant']['vm_box']              = nil
default['topology-truck']['acceptance']['Vagrant']['image_url']           = nil
default['topology-truck']['acceptance']['Vagrant']['vm_memory']           = nil
default['topology-truck']['acceptance']['Vagrant']['vm_cpus']             = nil
default['topology-truck']['acceptance']['vagrant']['network']             = nil
default['topology-truck']['acceptance']['vagrant']['key_file']            = nil
default['topology-truck']['acceptance']['vagrant']['chef_config']         = nil
default['topology-truck']['acceptance']['vagrant']['chef_version']        = nil
