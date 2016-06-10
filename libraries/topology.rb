#
# Cookbook Name:: topo
#
# Copyright (c) 2015 ThirdWave Insights, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# rubocop:disable LineLength
# rubocop:disable ClassLength

require 'chef/data_bag_item'
require_relative './node'

class Topo
  # Handle topology data from data bag item
  class Topology
    @topos = {}

    attr_reader :name, :version, :buildstamp, :buildid, :strategy, :tp_chef_environment

    # class method to get or create Topo instance
    def self.get_topo(name, data_bag = 'topologies')
      unless @topos[name]
        @topos[name] = load_from_bag(name, name, data_bag)

        return nil unless @topos[name]
      end
      @topos[name]
    end

    def self.load_from_bag(name, item, data_bag)
      raw_data = Chef::DataBagItem.load(data_bag, item)
      raw_data['name'] = item if raw_data # Restore name attribute - chef bug
      Topo::Topology.new(name, raw_data.to_hash) if raw_data
    rescue Net::HTTPServerException => e
      raise unless e.to_s =~ /^404/
      nil
    end

    def self.load_from_file(filename)
      return unless File.exist?(filename)
      hash = Chef::JSONCompat.from_json(File.read(filename))
      topo = Topo::Topology.new(hash['name'], hash)
      topo
    end

    # rubocop:disable AbcSize
    # rubocop:disable MethodLength
    def initialize(name, raw_data)
      @raw_data = raw_data
      @name = @raw_data['name'] || name
      @version = @raw_data['version']
      @buildstamp = @raw_data['buildstamp']
      @buildid = @raw_data['buildid']
      @strategy = @raw_data['strategy']
      @tp_chef_environment = @raw_data['chef_environment']
      @tp_provisioning =   @raw_data['provisioning']

      @raw_nodes = @raw_data['nodes'] || []
      @chef_environment = @raw_data['chef_environment']
      @tags = @raw_data['tags']
      @attributes = @raw_data['attributes'] || @raw_data['normal'] || {}

      @nd_provision = {}
      @nd_prov = false
      @tp_aws  = false
      @tp_ssh  = false

      nodes
    end
    # rubocop:enable AbcSize
    # rubocop:enable MethodLength

    def nodes
      return @nodes if @nodes
      @nodes = @raw_nodes.map do |node_data|
        Topo::Node.new(inflate_node(node_data))
      end
    end

    def name
      return @name if @name
      'error_name_unknown'
    end

    # recursive merge that retains all keys
    def prop_merge(hash, other_hash)
      other_hash.each do |key, val|
        if val.is_a?(Hash) && hash[key]
          prop_merge(hash[key], val)
        else
          hash[key] = val
        end
      end
      hash
    end

    # Expand each node in the JSON to contain a complete definition,
    # taking defaults from topology where not defined in the node json
    def inflate_node(node_data)
      node_data['chef_environment'] ||= @chef_environment if @chef_environment
      node_data['attributes'] = inflate_attrs(node_data)

      @nd_prov = true if node_data['provisioning']
      #
      extract_provisioning_details(node_data['name'], node_data['provisioning']) if node_data['provisioning']
      #
      if @tags
        node_data['tags'] ||= []
        node_data['tags'] |= @tags
      end
      node_data
    end

    def inflate_attrs(node_data)
      attrs = node_data['attributes'] || node_data['normal'] || {}
      attrs['topo'] ||= {}
      attrs['topo']['name'] = @name
      attrs['topo']['blueprint_name'] = @blueprint if @blueprint
      prop_merge(
        Marshal.load(Marshal.dump(@attributes)),
        attrs
      )
    end

    def get_node(name, type = nil)
      node = nodes.find do |n|
        n.name == name
      end

      if !node && type
        # if specific node doesn't exist, look for node of same type
        node = nodes.find do |n|
          n.node_type == type
        end
      end

      node
    end

    # { drv1: { machine_options: {}, drv2: {machine_options: {} }
    def extract_provisioning_details(node_name, clause)
      clause.each do |drv, mo|
        #
        @tp_aws = true if drv == 'aws'
        @tp_ssh = true if drv == 'ssh'
        #
        @nd_provision[node_name] = {} unless @nd_provision[node_name]
        @nd_provision[node_name][drv] = { machine_options: mo['machine_options'] }
        #
      end
    end

    def driver(nd_type, drv_type)
      return false unless @nd_provision[nd_type]
      return false unless @nd_provision[nd_type][drv_type]
      true
    end

    def aws_driver?
      return true if @tp_aws
      return false unless @tp_provisioning
      return true if @tp_provisioning['aws']
      false
    end

    def ssh_driver?
      return true if @tp_ssh
      return false unless @tp_provisioning
      return true if @tp_provisioning['ssh']
      false
    end

    def node_machine_options(nd_name, drv_type)
      return {} unless @nd_provision[nd_name]
      return {} unless @nd_provision[nd_name][drv_type]
      return {} unless @nd_provision[nd_name][drv_type][:machine_options]
      @nd_provision[nd_name][drv_type][:machine_options]
    end

    def provisionable?
      return true if @tp_provisioning
      return true if @nd_prov
      false
    end

    def nd_provisionable?(node)
      return false unless @nd_prov
      return false if @nd_provision == {}
      return false unless @nd_provision[node]
      true
    end
  end
end
