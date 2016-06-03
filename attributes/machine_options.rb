#
#
# rubocop:disable LineLength
#
# Machine options for aws across the pipeline
default['topology-truck']['pipeline']['aws']['key_name'] = ENV['USER']
default['topology-truck']['pipeline']['aws']['ssh_username']            = 'ubuntu'         # TODO: jws specific
default['topology-truck']['pipeline']['aws']['security_group_ids']      = ['sg-ecaf5b89']  # TODO: jws specific
default['topology-truck']['pipeline']['aws']['image_id']                = nil
default['topology-truck']['pipeline']['aws']['instance_type']           = 't2.micro'       # TODO: jws specific
default['topology-truck']['pipeline']['aws']['subnet_id']               = 'subnet-bb898bcf' # TODO: jws specific
default['topology-truck']['pipeline']['aws']['bootstrap_proxy']         =
  ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
default['topology-truck']['pipeline']['aws']['chef_config']             = nil
default['topology-truck']['pipeline']['aws']['chef_version']            = '12.8.1'          # TODO: jws specific
default['topology-truck']['pipeline']['aws']['use_private_ip_for_ssh'] = false
#
# Machine options for ssh across the pipeline
default['topology-truck']['pipeline']['ssh']['key_file']                = nil
default['topology-truck']['pipeline']['ssh']['prefix']                  = nil
default['topology-truck']['pipeline']['ssh']['ssh_username']            = 'vagrant'        # TODO: jws specific
default['topology-truck']['pipeline']['ssh']['ssh_password']            = 'vagrant'        # TODO: jws specific
default['topology-truck']['pipeline']['ssh']['bootstrap_proxy']         =
  ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
default['topology-truck']['pipeline']['ssh']['chef_config']             = nil
default['topology-truck']['pipeline']['ssh']['chef_version']            = '12.8.1'         # TODO: jws specific
default['topology-truck']['pipeline']['ssh']['use_private_ip_for_ssh'] = false
#
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
