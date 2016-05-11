# patterned after helper_publish_spec.rb in delivery-truck

require 'spec_helper'

describe TopologyTruck::Helpers::Publish do
  let(:node) { Chef::Node.new }

  shared_examples_for 'Pipelines --- Stages --- Topologies --- and more ... ' do
    context 'when config value is unset' do
      it 'returns false' do
        expect(described_class.send(method, node)).to eql(false)
      end
    end

    context 'when config value is set' do
      it 'returns the value' do
        node.default['delivery']['config']['topology-truck'][node_field] = t_n_a
        expect(described_class.send(method, node)).to eql(true)

        node.default['delivery']['config']['topology-truck'][node_field] = f_n_a
        expect(described_class.send(method, node)).to eql(false)
      end
    end
  end

  describe '.upload_cookbook_to_chef_server?' do
    let(:method) { :upload_cookbook_to_chef_server? }
    let(:node_field) { 'chef_server' }
    let(:t_n_a) { true }
    let(:f_n_a) { false }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end

  describe '.share_cookbook_to_supermarket?' do
    let(:method) { :share_cookbook_to_supermarket? }
    let(:node_field) { 'supermarket' }
    let(:t_n_a) { 'https://supermarket.chef.io' }
    let(:f_n_a) { false }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end

  describe '.use_custom_supermarket_credentials?' do
    let(:method) { :use_custom_supermarket_credentials? }
    let(:node_field) { 'supermarket-custom-credentials' }
    let(:t_n_a) { true }
    let(:f_n_a) { false }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end

  describe '.push_repo_to_github?' do
    let(:method) { :push_repo_to_github? }
    let(:node_field) { 'github' }
    let(:t_n_a) { true }
    let(:f_n_a) { false }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end

  describe '.push_repo_to_git?' do
    let(:method) { :push_repo_to_git? }
    let(:node_field) { 'git' }
    let(:t_n_a) { true }
    let(:f_n_a) { false }

    it_behaves_like 'Pipelines --- Stages --- Topologies --- and more ... '
  end
end
