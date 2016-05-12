# patterned after helper_publish_spec.rb in delivery-truck

require 'spec_helper'

# rubocop:disable LineLength
# rubocop:disable HashSyntax
aws_machine_template = { :convergence_options => { :bootstrap_proxy => nil, :chef_config => nil, :chef_version => '12.8.1', :install_sh_path => nil }, :bootstrap_options => { :instance_type => nil, :key_name => nil, :security_group_ids => nil }, :ssh_username => nil, :image_id => nil, :use_private_ip_for_ssh => nil }
ssh_machine_template = { :convergence_options => { :bootstrap_proxy => nil, :chef_config => nil, :chef_version => '12.8.1', :install_sh_path => nil }, :transport_options => { :username => 'vagrant', :ssh_options => { :user => 'vagrant', :password => 'vagrant', :keys => [] }, :options => { :prefix => nil } } }
# rubocop:enable HashSyntax
# rubocop:enable LineLength

describe TopologyTruck::ConfigParms do
  let(:node) { Chef::Node.new }

  shared_examples_for 'Pipelines --- Stages --- Topologies --- and more ... ' do
    context 'Check all the config.json options...' do
      it 'check for aws driver at pipeline level' do
        expect(tp_truck_parms.driver).to eql(driver)
      end

      it 'check for driver type at pipeline level' do
        expect(tp_truck_parms.driver_type).to eql(driver_type)
      end

      it 'check for machine option template for current driver' do
        expect(tp_truck_parms.machine_options).to eql(template_mach_opts)
      end

      it 'check for driver at pipeline level' do
        expect(tp_truck_parms.pipeline_mach_opts).to eql(pipeline_mach_opts)
      end

      it 'topology list for verify' do
        expect(tp_truck_parms.topology_list_for_stage('verify')).to eql([])
      end

      it 'topology list for build' do
        expect(tp_truck_parms.topology_list_for_stage('build')).to eql([])
      end

      it 'topology list for acceptance' do
        expect(tp_truck_parms.topology_list_for_stage('acceptance')).to eql([])
      end

      it 'topology list for union' do
        expect(tp_truck_parms.topology_list_for_stage('union')).to eql([])
      end

      it 'topology list for rehearsal' do
        expect(tp_truck_parms.topology_list_for_stage('rehearsal')).to eql([])
      end

      it 'topology list for delivered' do
        expect(tp_truck_parms.topology_list_for_stage('delivered')).to eql([])
      end

      it 'topology list for PIPELINE' do
        expect(tp_truck_parms.topology_list_for_pipeline).to eql([])
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
    let(:pipeline_mach_opts) { {} }

    let(:tp_truck_parms) { TopologyTruck::ConfigParms.new(raw_data) }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end

  describe 'simple ssh driver for pipeline' do
    # rubocop:disable LineLength
    raw_data = { 'topology-truck' => { 'pipeline' => { 'driver' => 'ssh' } } } # ##############
    # rubocop:enable LineLength

    let(:driver) { 'ssh' }
    let(:driver_type) { 'ssh' }
    let(:template_mach_opts) { ssh_machine_template }
    let(:pipeline_mach_opts) { {} }

    let(:tp_truck_parms) { TopologyTruck::ConfigParms.new(raw_data) }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end

  describe 'simple ssh driver for pipeline' do
    # rubocop:disable LineLength
    raw_data = { 'topology-truck' => { 'pipeline' => { 'driver' => 'aws' }, 'stages' => {} } }
    # rubocop:enable LineLength

    let(:driver) { 'aws' }
    let(:driver_type) { 'aws' }
    let(:template_mach_opts) { aws_machine_template }
    let(:pipeline_mach_opts) { {} }

    let(:tp_truck_parms) { TopologyTruck::ConfigParms.new(raw_data) }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end
end
