require 'spec_helper'

describe 'topology-truck::publish' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['delivery']['workspace']['root'] = '/tmp'
      node.set['delivery']['workspace']['repo'] = '/tmp/repo'
      node.set['delivery']['workspace']['chef'] = '/tmp/chef'
      node.set['delivery']['workspace']['cache'] = '/tmp/cache'

      node.set['delivery']['change']['enterprise'] = 'Chef'
      node.set['delivery']['change']['organization'] = 'Delivery'
      node.set['delivery']['change']['project'] = 'Secret'
      node.set['delivery']['change']['pipeline'] = 'master'
      node.set['delivery']['change']['change_id'] = 'aaaa-bbbb-cccc'
      node.set['delivery']['change']['patchset_number'] = '1'
      node.set['delivery']['change']['stage'] = 'union'
      node.set['delivery']['change']['phase'] = 'deploy'
      node.set['delivery']['change']['git_url'] = 'https://git.co/my_project.git'
      node.set['delivery']['change']['sha'] = '0123456789abcdef'
      node.set['delivery']['change']['patchset_branch'] = 'mypatchset/branch'
    end.converge(described_recipe)
  end

  # We need a double for the relevant parts of the DeliverySugar change object
  let(:change) do
    double(
      'change',
      workspace_repo: 'workspace_repo',
      workspace_path: 'workspace_path',
      changed_files: [
        'topologies/bp1/topo1.json',
        'topologies/bp1/README.md',
        'README.md'
      ]
    )
  end

  let :one_changed_topology do
    { 'topologies/bp1/topo1.json' =>
      Topo::Topology.new(
        'topo1',
        'name' => 'topo1'
      )
    }
  end

  let :topo_change do
    double(
      'topo_change',
      changed_topologies: one_changed_topology
    )
  end

  context 'when a single topology has been modified' do
    before do
      allow_any_instance_of(Chef::Recipe).to receive(:change).and_return(change)
    end

    it 'runs knife topo against that topology' do
      config_args = '--config workspace_path/.chef/knife.rb'
      expect(TopologyTruck::Change).to receive(:new).and_return(topo_change)
      expect(chef_run).to run_execute(
        'publish topology topo1 to Chef Server').with(
          command: 'knife topo import \"/tmp/repo/topologies/bp1/topo1.json\" '\
            "#{config_args} && knife topo create topo1 --yes #{config_args}"
        )
    end
  end
end
