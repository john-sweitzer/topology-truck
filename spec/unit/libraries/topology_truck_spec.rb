# patterned after helper_publish_spec.rb in delivery-truck

require 'spec_helper'

# rubocop:disable HashSyntax
# rubocop:disable LineLength
aws_machine_template = { :convergence_options => { :bootstrap_proxy => nil, :chef_config => nil, :chef_version => '12.8.1', :install_sh_path => nil }, :bootstrap_options => { :instance_type => nil, :key_name => nil, :security_group_ids => nil }, :ssh_username => nil, :image_id => nil, :use_private_ip_for_ssh => nil }
ssh_machine_template = { :convergence_options => { :bootstrap_proxy => nil, :chef_config => nil, :chef_version => '12.8.1', :install_sh_path => nil }, :transport_options => { :username => 'vagrant', :ssh_options => { :user => 'vagrant', :password => 'vagrant', :keys => [] }, :options => { :prefix => nil } } }
# rubocop:enable HashSyntax
# rubocop:enable LineLength

describe TopologyTruck::ConfigParms do
  let(:node) { Chef::Node.new }

  shared_examples_for 'Pipelines --- Stages --- Topologies --- and more ... ' do
    context 'Check all the config.json options...' do
      it 'check for aws driver at pipeline level' do
        expect(tp_trk_parms.pl_driver).to eql(driver)
      end

      it 'check for driver type at pipeline level' do
        expect(tp_trk_parms.pl_driver_type).to eql(driver_type)
      end

      it 'check for machine option template for current driver' do
        expect(tp_trk_parms.machine_options).to eql(template_mach_opts)
      end

      it 'check for driver at pipeline level' do
        expect(tp_trk_parms.pl_machine_options).to eql(pl_machine_options)
      end

      it 'topology list for verify' do
        # rubocop:disable LineLength
        expect(tp_trk_parms.st_topologies('verify')).to eql([{ 'none_specified_for_stage' => 'verify' }])
        # rubocop:enable LineLength
      end

      it 'topology list for build' do
        # rubocop:disable LineLength
        expect(tp_trk_parms.st_topologies('build')).to eql([{ 'none_specified_for_stage' => 'build' }])
        # rubocop:enable LineLength
      end

      it 'topology list for acceptance' do
        expect(tp_trk_parms.st_topologies('acceptance')).to eql(a_tps)
      end

      it 'topology list for union' do
        expect(tp_trk_parms.st_topologies('union')).to eql(u_tps)
      end

      it 'topology list for rehearsal' do
        expect(tp_trk_parms.st_topologies('rehearsal')).to eql(r_tps)
      end

      it 'topology list for delivered' do
        expect(tp_trk_parms.st_topologies('delivered')).to eql(d_tps)
      end

      it 'topology list for PIPELINE' do
        expect(tp_trk_parms.pl_topologies).to eql(pl_tps)
      end
    end
  end

  describe '.simple aws driver for pipeline' do
    # rubocop:disable LineLength
    raw_data = { 'topology-truck' => { 'pipeline' => { 'driver' => 'aws' } } } # ###############
    # rubocop:enable LineLength

    let(:driver) { 'aws' }
    let(:driver_type) { 'aws' }
    let(:template_mach_opts) { aws_machine_template }
    let(:pl_machine_options) { {} }
    let(:a_tps) { [] }
    let(:u_tps) { [] }
    let(:r_tps) { [] }
    let(:d_tps) { [] }
    let(:pl_tps) { [] }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data) }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end

  describe 'simple ssh driver for pipeline' do
    # rubocop:disable LineLength
    raw_data = { 'topology-truck' => { 'pipeline' => { 'driver' => 'ssh' } } } # ##############
    # rubocop:enable LineLength

    let(:driver) { 'ssh' }
    let(:driver_type) { 'ssh' }
    let(:template_mach_opts) { ssh_machine_template }
    let(:pl_machine_options) { {} }
    let(:a_tps) { [] }
    let(:u_tps) { [] }
    let(:r_tps) { [] }
    let(:d_tps) { [] }
    let(:pl_tps) { [] }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data) }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end

  describe 'simple ssh driver for pipeline' do
    # rubocop:disable LineLength
    raw_data = { 'topology-truck' => { 'pipeline' => { 'driver' => 'aws' }, 'stages' => {} } }
    # rubocop:enable LineLength

    let(:driver) { 'aws' }
    let(:driver_type) { 'aws' }
    let(:template_mach_opts) { aws_machine_template }
    let(:pl_machine_options) { {} }
    let(:a_tps) { [] }
    let(:u_tps) { [] }
    let(:r_tps) { [] }
    let(:d_tps) { [] }
    let(:pl_tps) { [] }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data) }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end

  describe 'simple ssh driver for pipeline' do
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

    let(:driver) { 'aws' }
    let(:driver_type) { 'aws' }
    let(:template_mach_opts) { aws_machine_template }
    let(:pl_machine_options) { {} }
    let(:a_tps) { ['a'] }
    let(:u_tps) { ['u'] }
    let(:r_tps) { ['r'] }
    let(:d_tps) { ['d'] }
    let(:pl_tps) { %w(a u r d) }

    let(:tp_trk_parms) { TopologyTruck::ConfigParms.new(raw_data) }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end
end
