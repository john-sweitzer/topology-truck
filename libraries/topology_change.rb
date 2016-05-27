require_relative 'topology'

class TopologyTruck
  # Wrap DeliverySugar::Change to support topology changes
  class Change
    def initialize(change)
      @change = change
    end

    # Returns a hash of topology objects in the changeset, indexed by
    # relative filepath
    def changed_topologies
      topologies = {}
      @change.changed_files.each do |file|
        result = file.match(%r{^topologies/[a-zA-Z0-9_-]*/[a-zA-Z0-9_-]*.json})
        next if result.nil?
        full_path = File.join(@change.workspace_repo, file)
        topo = Topo::Topology.load_from_file(full_path)
        topologies[file] = topo if topo
      end
      topologies
    end
  end
end
