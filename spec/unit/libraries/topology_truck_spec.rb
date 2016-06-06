# patterned after helper_publish_spec.rb in delivery-truck
#
#
# rubocop:disable HashSyntax
# rubocop:disable LineLength

require 'spec_helper'

aws_machine_template = { :convergence_options => { :bootstrap_proxy => nil, :chef_config => nil, :chef_version => '12.8.1', :install_sh_path => nil }, :bootstrap_options => { :instance_type => 'instance.type.p', :key_name => nil, :security_group_ids => ['security-group-id-p'], :subnet_id => 'subnet_id_p' }, :ssh_username => 'ssh_username_p', :image_id => nil, :use_private_ip_for_ssh => false, :transport_address_location => 'public_ip' }
ssh_machine_template = { :convergence_options => { :bootstrap_proxy => nil, :chef_config => nil, :chef_version => '12.8.1', :install_sh_path => nil }, :transport_options => { :username => 'vagrant', :ssh_options => { :user => 'vagrant', :password => 'vagrant', :keys => [] }, :options => { :prefix => nil } } }

describe TopologyTruck::ConfigParms do
  let(:node) do
    l_node = Chef::Node.new
    # Machine options for aws across the pipeline
    l_node.normal['topology-truck']['pipeline']['aws']['key_name'] = ENV['USER']
    l_node.normal['topology-truck']['pipeline']['aws']['ssh_username']            = 'ssh_username_p'
    l_node.normal['topology-truck']['pipeline']['aws']['security_group_ids']      = ['security-group-id-p']
    l_node.normal['topology-truck']['pipeline']['aws']['image_id']                = nil
    l_node.normal['topology-truck']['pipeline']['aws']['instance_type']           = 'instance.type.p'
    l_node.normal['topology-truck']['pipeline']['aws']['subnet_id']               = 'subnet_id_p'
    l_node.normal['topology-truck']['pipeline']['aws']['bootstrap_proxy']         =
      ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
    l_node.normal['topology-truck']['pipeline']['aws']['chef_config']             = nil
    l_node.normal['topology-truck']['pipeline']['aws']['chef_version']            = '12.8.1'
    l_node.normal['topology-truck']['pipeline']['aws']['use_private_ip_for_ssh'] = false
    #
    # Machine options for ssh across the pipeline
    l_node.normal['topology-truck']['pipeline']['ssh']['key_file']                = nil
    l_node.normal['topology-truck']['pipeline']['ssh']['prefix']                  = nil
    l_node.normal['topology-truck']['pipeline']['ssh']['ssh_username']            = 'vagrant'
    l_node.normal['topology-truck']['pipeline']['ssh']['ssh_password']            = 'vagrant'
    l_node.normal['topology-truck']['pipeline']['ssh']['bootstrap_proxy']         =
      ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
    l_node.normal['topology-truck']['pipeline']['ssh']['chef_config']             = nil
    l_node.normal['topology-truck']['pipeline']['ssh']['chef_version']            = '12.8.1'
    l_node.normal['topology-truck']['pipeline']['ssh']['use_private_ip_for_ssh'] = false
    l_node
  end

  shared_examples_for 'Machine Options Examples' do
    context 'Check all the config.json options...' do
      it 'PIPELINE details? [pl_level?]' do
        expect(tp_trk_parms.pl_level?).to eql(pl_level)
      end

      it 'STAGE details? [st_level?]' do
        expect(tp_trk_parms.st_level?).to eql(st_level)
      end

      it 'TOPOLOGY details? [tp_levels?]' do
        expect(tp_trk_parms.tp_level?).to eql(tp_level)
      end

      it 'machine_options' do
        expect(tp_trk_parms.machine_options).to eql(template_mach_opts)
      end

      it 'pl_machine_options' do
        expect(tp_trk_parms.pl_machine_options).to eql(pl_machine_options)
      end

      it 'st_machine_options' do
        expect(tp_trk_parms.st_machine_options('acceptance')).to eql(st_machine_options)
      end

      it 'tp_machine_options' do
        expect(tp_trk_parms.tp_machine_options('_test_')).to eql(tp_machine_options)
      end
    end
  end

  shared_examples_for 'pl --- st --- tp --- more' do
    context 'Check all the config.json options...' do
      it 'PIPELINE details? [pl_level?]' do
        expect(tp_trk_parms.pl_level?).to eql(pl_level)
      end

      it 'STAGE details? [st_level?]' do
        expect(tp_trk_parms.st_level?).to eql(st_level)
      end

      it 'TOPOLOGY details? [tp_levels?]' do
        expect(tp_trk_parms.tp_level?).to eql(tp_level)
      end

      it 'check for aws driver at pipeline level [pl_driver]' do
        expect(tp_trk_parms.pl_driver).to eql(driver)
      end

      it 'check for driver type at pipeline level [pl_driver_type]' do
        expect(tp_trk_parms.pl_driver_type).to eql(driver_type)
      end

      it 'machine_options' do
        expect(tp_trk_parms.machine_options).to eql(template_mach_opts)
      end

      it 'pl_machine_options' do
        expect(tp_trk_parms.pl_machine_options).to eql(pl_machine_options)
      end

      it 'st_topologies(verify)' do
        expect(tp_trk_parms.st_topologies('verify')).to eql([])
      end

      it 'st_topologies(build)' do
        expect(tp_trk_parms.st_topologies('build')).to eql([])
      end

      it 'st_topologies(acceptance)' do
        expect(tp_trk_parms.st_topologies('acceptance')).to eql(a_tps)
      end

      it 'st_topologies(union)' do
        expect(tp_trk_parms.st_topologies('union')).to eql(u_tps)
      end

      it 'st_topologies(rehearsal)' do
        expect(tp_trk_parms.st_topologies('rehearsal')).to eql(r_tps)
      end

      it 'st_topologies(delivered)' do
        expect(tp_trk_parms.st_topologies('delivered')).to eql(d_tps)
      end

      it 'st_driver_type(acceptance)' do
        expect(tp_trk_parms.st_driver_type('acceptance')).to eql(a_drv)
      end

      it 'st_driver_type(union)' do
        expect(tp_trk_parms.st_driver_type('union')).to eql(u_drv)
      end

      it 'st_driver_type(rehearsal)' do
        expect(tp_trk_parms.st_driver_type('rehearsal')).to eql(r_drv)
      end

      it 'st_driver_type(delivered)' do
        expect(tp_trk_parms.st_driver_type('delivered')).to eql(d_drv)
      end

      it 'pl_topologies' do
        expect(tp_trk_parms.pl_topologies).to eql(pl_tps)
      end

      it 'any_ssh_drivers?' do
        expect(tp_trk_parms.any_ssh_drivers?).to eql(any_ssh)
      end

      it 'any_aws_drivers?' do
        expect(tp_trk_parms.any_aws_drivers?).to eql(any_aws)
      end
    end
  end

  describe '*** topology-truck: { } *** ' do
    raw_data = {
      'topology-truck' => {}
    }

    let(:pl_level) { false }
    let(:st_level) { false }
    let(:tp_level) { false }
    let(:driver) { '_unspecified_' }
    let(:driver_type) { '_unspecified_' }
    let(:template_mach_opts) { {} }
    let(:pl_machine_options) { {} }
    let(:a_tps) { [] }
    let(:u_tps) { [] }
    let(:r_tps) { [] }
    let(:d_tps) { [] }
    let(:a_drv) { '_unspecified_' }
    let(:u_drv) { '_unspecified_' }
    let(:r_drv) { '_unspecified_' }
    let(:d_drv) { '_unspecified_' }
    let(:pl_tps) { [] }
    let(:any_ssh) { false }
    let(:any_aws) { false }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data, node) }

    it_behaves_like 'pl --- st --- tp --- more'
  end

  describe '*** {pl: {}, st: {}, tp: {} } ***' do
    raw_data = {
      'topology-truck' => {
        'pipeline' => {},
        'stages' => {},
        'topologies' => {}
      }
    }

    let(:pl_level) { true }
    let(:st_level) { true }
    let(:tp_level) { true }
    let(:driver) { '_unspecified_' }
    let(:driver_type) { '_unspecified_' }
    let(:template_mach_opts) { {} }
    let(:pl_machine_options) { {} }
    let(:a_tps) { [] }
    let(:u_tps) { [] }
    let(:r_tps) { [] }
    let(:d_tps) { [] }
    let(:a_drv) { '_unspecified_' }
    let(:u_drv) { '_unspecified_' }
    let(:r_drv) { '_unspecified_' }
    let(:d_drv) { '_unspecified_' }
    let(:pl_tps) { [] }
    let(:any_ssh) { false }
    let(:any_aws) { false }
    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data, node) }

    it_behaves_like 'pl --- st --- tp --- more'
  end

  describe '*** pl driver only (aws) ***' do
    raw_data = {
      'topology-truck' => {
        'pipeline' => {
          'driver' => 'aws'
        }
      }
    }

    let(:pl_level) { true }
    let(:st_level) { false }
    let(:tp_level) { false }
    let(:driver) { 'aws' }
    let(:driver_type) { 'aws' }
    let(:template_mach_opts) { aws_machine_template }
    let(:pl_machine_options) { {} }
    let(:a_tps) { [] }
    let(:u_tps) { [] }
    let(:r_tps) { [] }
    let(:d_tps) { [] }
    let(:a_drv) { 'aws' }
    let(:u_drv) { 'aws' }
    let(:r_drv) { 'aws' }
    let(:d_drv) { 'aws' }
    let(:pl_tps) { [] }
    let(:any_ssh) { false }
    let(:any_aws) { true }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data, node) }

    it_behaves_like 'pl --- st --- tp --- more'
  end

  describe '*** pl driver only (ssh) ***' do
    raw_data = {
      'topology-truck' => {
        'pipeline' => {
          'driver' => 'ssh'
        }
      }
    }

    let(:pl_level) { true }
    let(:st_level) { false }
    let(:tp_level) { false }
    let(:driver) { 'ssh' }
    let(:driver_type) { 'ssh' }
    let(:template_mach_opts) { ssh_machine_template }
    let(:pl_machine_options) { {} }
    let(:a_tps) { [] }
    let(:u_tps) { [] }
    let(:r_tps) { [] }
    let(:d_tps) { [] }
    let(:a_drv) { 'ssh' }
    let(:u_drv) { 'ssh' }
    let(:r_drv) { 'ssh' }
    let(:d_drv) { 'ssh' }
    let(:pl_tps) { [] }
    let(:any_ssh) { true }
    let(:any_aws) { false }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data, node) }

    it_behaves_like 'pl --- st --- tp --- more'
  end

  describe '*** pl drv with st: {} ***' do
    raw_data = {
      'topology-truck' => {
        'pipeline' => {
          'driver' => 'aws'
        },
        'stages' => {}
      }
    }

    let(:pl_level) { true }
    let(:st_level) { true }
    let(:tp_level) { false }
    let(:driver) { 'aws' }
    let(:driver_type) { 'aws' }
    let(:template_mach_opts) { aws_machine_template }
    let(:pl_machine_options) { {} }
    let(:a_tps) { [] }
    let(:u_tps) { [] }
    let(:r_tps) { [] }
    let(:d_tps) { [] }
    let(:a_drv) { 'aws' }
    let(:u_drv) { 'aws' }
    let(:r_drv) { 'aws' }
    let(:d_drv) { 'aws' }
    let(:pl_tps) { [] }
    let(:any_ssh) { false }
    let(:any_aws) { true }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data, node) }

    it_behaves_like 'pl --- st --- tp --- more'
  end

  describe '*** single tp for a, u, r, d ***' do
    raw_data = {
      'topology-truck' => {
        'pipeline' => {
          'driver' => 'aws'
        },
        'stages' => {
          'acceptance' => { 'topologies' => ['a'] },
          'union' => { 'topologies' => ['u'] },
          'rehearsal' => { 'topologies' => ['r'] },
          'delivered' => { 'topologies' => ['d'] }
        }
      }
    }

    let(:pl_level) { true }
    let(:st_level) { true }
    let(:tp_level) { false }
    let(:driver) { 'aws' }
    let(:driver_type) { 'aws' }
    let(:template_mach_opts) { aws_machine_template }
    let(:pl_machine_options) { {} }
    let(:a_tps) { ['a'] }
    let(:u_tps) { ['u'] }
    let(:r_tps) { ['r'] }
    let(:d_tps) { ['d'] }
    let(:a_drv) { 'aws' }
    let(:u_drv) { 'aws' }
    let(:r_drv) { 'aws' }
    let(:d_drv) { 'aws' }
    let(:pl_tps) { %w(a u r d) }
    let(:any_ssh) { false }
    let(:any_aws) { true }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data, node) }

    it_behaves_like 'pl --- st --- tp --- more'
  end

  describe '*** no pl, single tp, all stages, mixed drivers ***' do
    raw_data = {
      'topology-truck' => {
        'stages' => {
          'acceptance' => {
            'topologies' => ['a'],
            'driver' => 'ssh'
          },
          'union' => {
            'topologies' => ['u'],
            'driver' => 'aws'
          },
          'rehearsal' => {
            'topologies' => ['r'],
            'driver' => 'ssh'
          },
          'delivered' => {
            'topologies' => ['d'],
            'driver' => 'aws'
          }
        }
      }
    }

    let(:pl_level) { false }
    let(:st_level) { true }
    let(:tp_level) { false }
    let(:driver) { '_unspecified_' }
    let(:driver_type) { '_unspecified_' }
    let(:template_mach_opts) { {} }
    let(:pl_machine_options) { {} }
    let(:a_tps) { ['a'] }
    let(:u_tps) { ['u'] }
    let(:r_tps) { ['r'] }
    let(:d_tps) { ['d'] }
    let(:a_drv) { 'ssh' }
    let(:u_drv) { 'aws' }
    let(:r_drv) { 'ssh' }
    let(:d_drv) { 'aws' }
    let(:pl_tps) { %w(a u r d) }
    let(:any_ssh) { true }
    let(:any_aws) { true }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data, node) }

    it_behaves_like 'pl --- st --- tp --- more'
  end

  describe '*** pl drv with some st drv ***' do
    raw_data = {
      'topology-truck' => {
        'pipeline' => {
          'driver' => 'aws'
        },
        'stages' => {
          'acceptance' => {
            'topologies' => ['a'],
            'driver' => 'ssh'
          },
          'union' => {
            'topologies' => ['u']
          },
          'rehearsal' => {
            'topologies' => ['r'],
            'driver' => 'ssh'
          },
          'delivered' => {
            'topologies' => ['d']
          }
        }
      }
    }

    let(:pl_level) { true }
    let(:st_level) { true }
    let(:tp_level) { false }
    let(:driver) { 'aws' }
    let(:driver_type) { 'aws' }
    let(:template_mach_opts) { aws_machine_template }
    let(:pl_machine_options) { {} }
    let(:a_tps) { ['a'] }
    let(:u_tps) { ['u'] }
    let(:r_tps) { ['r'] }
    let(:d_tps) { ['d'] }
    let(:a_drv) { 'ssh' }
    let(:u_drv) { 'aws' }
    let(:r_drv) { 'ssh' }
    let(:d_drv) { 'aws' }
    let(:pl_tps) { %w(a u r d) }
    let(:any_ssh) { true }
    let(:any_aws) { true }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data, node) }

    it_behaves_like 'pl --- st --- tp --- more'
  end

  describe 'Add machine options' do
    raw_data = {
      'topology-truck' => {
        'pipeline' => {
          'driver' => 'aws',
          'machine_options' => {
            bootstrap_options: {
              instance_type:      'INSTANCE_TYPE',
              key_name:           'KEY_NAME',
              security_group_ids: 'SECURITY_GROUP_IDS'
            }
          }
        },
        'stages' => {
          'acceptance' => {
            'topologies' => ['a'],
            'driver' => 'ssh',
            'machine_options' => {
              bootstrap_options: {
                instance_type:      'ACCEPT_INSTANCE_TYPE',
                key_name:           'ACCEPT_KEY_NAME',
                security_group_ids: 'ACCEPT_SECURITY_GROUP_IDS'
              }
            }
          },
          'union' => {
            'topologies' => ['u'],
            'driver' => 'aws'
          },
          'rehearsal' => {
            'topologies' => ['r'],
            'driver' => 'ssh'
          },
          'delivered' => {
            'topologies' => ['d'],
            'driver' => 'aws'
          }
        },
        'topologies' => {
          'test' => {
            'stage' => 'delivered',
            'driver' => 'ssh',
            'machine_options' => {
              bootstrap_options: {
                instance_type:      'TST_INSTANCE_TYPE',
                key_name:           'TST_KEY_NAME',
                security_group_ids: 'TST_SECURITY_GROUP_IDS'
              }
            }
          }
        }
      }
    }

    let(:pl_level) { true }
    let(:st_level) { true }
    let(:tp_level) { true }
    let(:driver) { 'aws' }
    let(:driver_type) { 'aws' }
    let(:template_mach_opts) { aws_machine_template }
    let(:pl_machine_options) { { :bootstrap_options => { :instance_type => 'INSTANCE_TYPE', :key_name => 'KEY_NAME', :security_group_ids => 'SECURITY_GROUP_IDS' } } }
    let(:st_machine_options) { { :bootstrap_options => { :instance_type => 'ACCEPT_INSTANCE_TYPE', :key_name => 'ACCEPT_KEY_NAME', :security_group_ids => 'ACCEPT_SECURITY_GROUP_IDS' } } }
    let(:tp_machine_options) { { :bootstrap_options => { :security_group_ids => 'TOPOLOGY_TEST_SECURITY_GROUP_ID' } } }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data, node) }

    it_behaves_like 'Machine Options Examples'
  end

  describe 'Add machine options for pl st and tp' do
    raw_data = {
      'topology-truck' => {
        'pipeline' => {
          'driver' => 'aws',
          'machine_options' => {
            bootstrap_options: {
              instance_type:      'PIPELINE_INSTANCE_TYPE'
            }
          }
        },
        'stages' => {
          'acceptance' => {
            'topologies' => ['tp_a'],
            'driver' => 'aws',
            'machine_options' => {
              bootstrap_options: {
                key_name:           'STAGE_ACCEPT_KEY_NAME'
              }
            }
          },
          'union' => {
            'topologies' => ['tp_u'],
            'driver' => 'aws'
          },
          'rehearsal' => {
            'topologies' => ['tp_r'],
            'driver' => 'ssh'
          },
          'delivered' => {
            'topologies' => ['tp_d'],
            'driver' => 'aws'
          }
        },
        'topologies' => {
          'another' => {
            'stage' => 'acceptance',
            'driver' => 'aws',
            'machine_options' => {
              convergence_options: {
                chef_config: 'TOPOLOGY_TEST_CHEF_CONFIG'
              }
            }
          }
        }
      }
    }

    let(:pl_level) { true }
    let(:st_level) { true }
    let(:tp_level) { true }
    let(:driver) { 'aws' }
    let(:driver_type) { 'aws' }
    let(:template_mach_opts) { aws_machine_template }
    let(:pl_machine_options) { { :bootstrap_options => { :instance_type => 'PIPELINE_INSTANCE_TYPE' } } }
    let(:st_machine_options) { { :bootstrap_options => { :key_name => 'STAGE_ACCEPT_KEY_NAME' } } }
    let(:tp_machine_options) { { :bootstrap_options => { :security_group_ids => 'TOPOLOGY_TEST_SECURITY_GROUP_ID' } } }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data, node) }

    it_behaves_like 'Machine Options Examples'
  end
end
