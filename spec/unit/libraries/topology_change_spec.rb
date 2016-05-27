require 'spec_helper'

describe TopologyTruck::Change do
  # We need a double for the relevant parts of the DeliverySugar change object
  let(:change) do
    double(
      'change',
      workspace_repo: 'workspace_repo',
      changed_files: [
        'topologies/bp1/topo1.json',
        'topologies/bp1/README.md',
        'README.md'
      ]
    )
  end
  let(:subject) { TopologyTruck::Change.new(change) }

  describe '.changed_topologies' do
    let(:result) { ['workspace_repo/topologies/bp1/topo1.json'] }
    let(:topo1) { Topo::Topology.new('topo1', 'name' => 'topo1') }

    it 'returns a unique list of topologies modified in the changeset' do
      expect(Topo::Topology).to receive(:load_from_file).with(
        'workspace_repo/topologies/bp1/topo1.json').and_return(topo1)

      expect(subject.changed_topologies).to eql(
        'topologies/bp1/topo1.json' => topo1)
    end
  end
end
