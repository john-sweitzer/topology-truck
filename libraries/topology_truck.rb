#
# Cookbook Name:: topology-truck
#
# Copyright (c) 2016 ThirdWave Insights, LLC.
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

require 'chef/data_bag_item'
require_relative './node'

# rubocop:disable ClassLength
class TopologyTruck
  # Handle config.json for topology-truck
  class ConfigParms
    @stage_topologies = {}

    # class method to get or create Topo instance
    def self.get_topo(name, data_bag = 'topologies')
      unless @topos[name]
        @topos[name] = load_from_bag(name, name, data_bag)
        return nil unless @topos[name]
      end
      @topos[name]
    end

    def self.load_from_bag(name, item, data_bag)
      begin
        raw_data = Chef::DataBagItem.load(data_bag, item)
        raw_data['name'] = item if raw_data # Restore name attr - chef bug
        topo = Topo::Topology.new(name, raw_data.to_hash) if raw_data
      rescue Net::HTTPServerException => e
        raise unless e.to_s =~ /^404/
      end
      topo
    end

    def initialize(raw_data, _stage = 'acceptance')
      @raw_data = raw_data['topology-truck'] || raw_data['topology_truck'] || {}
      capture_pipeline_details
      capture_stage_details
      capture_topology_details
      ############### Temporary code until we decide how to prime initial value
      @ssh_user = 'vagrant'
      @ssh_user_pwd = 'vagrant'
      @chef_version = '12.8.1'
    end

    # Extract the pipeline options from the config.json details
    def capture_pipeline_details
      m = 'topology-truck cb: No PIPELINE{} details specified.'
      Chef::Log.warn(m) unless @raw_data['pipeline']
      return unless @raw_data['pipeline']

      @driver_type = 'default'
      @driver = @raw_data['pipeline']['driver'] || ''
      @driver_type = driver.split(':', 2)[0] if @driver
      @pipeline_mach_opts = @raw_data['pipeline']['machine_options'] || {}
    end

    #
    # Extract stage details from the config.json file...
    #
    def capture_stage_details
      clause = @raw_data['stages']
      @acceptance_topologies  = extract_topology(clause, 'acceptance')
      @union_topologies       = extract_topology(clause, 'union')
      @rehearsal_topologies   = extract_topology(clause, 'rehearsal')
      @delivered_topologies   = extract_topology(clause, 'delivered')
      m = 'topology-truck cb: No STAGE{} details specified.'
      Chef::Log.warn(m) unless clause
      @pipeline_topologies = @acceptance_topologies + @union_topologies +
                             @rehearsal_topologies + @delivered_topologies
    end

    def extract_topology(clause, stage)
      return [] unless clause
      return [] unless clause[stage]
      clause[stage]['topologies'] || []
    end

    #
    #
    #
    def capture_topology_details
      # Do we have topologies detail...
      if @raw_data['topologies']
        #
      else Chef::Log.warn('topology-truck cb: No TOPOLOGY{} details specified.')
      end
    end

    def driver
      return @driver if @driver
      'default'
    end

    def driver_type
      return @driver_type if @driver_type
      'default'
    end

    # @returns machine option template based on driver type...
    # Templates are derived from patterns in Chef's Delivery-Cluster cookbook...
    def machine_options
      master_template = {}
      master_template = aws_template if driver_type == 'aws'
      master_template = vagrant_template if driver_type == 'vagrant'
      master_template = ssh_template if driver_type == 'ssh'
      master_template
    end

    # rubocop:disable MethodLength
    def ssh_template
      master_template = {
        convergence_options: {
          bootstrap_proxy: @bootstrap_proxy,
          chef_config: @chef_config,
          chef_version: @chef_version,
          install_sh_path: @install_sh_path
        },
        transport_options: {
          username: @ssh_user,
          ssh_options: {
            user: @ssh_user,
            password: @ssh_user_pwd,
            keys: @key_file.nil? ? [] : [@key_file]
          },
          options: {
            prefix: @prefix
          }
        }
      }
      master_template
    end

    def aws_template
      master_template = {
        convergence_options: {
          bootstrap_proxy: @bootstrap_proxy,
          chef_config: @chef_config,
          chef_version: @chef_version,
          install_sh_path: @install_sh_path
        },
        bootstrap_options: {
          instance_type:      @instance_type,
          key_name:           @key_name,
          security_group_ids: @security_group_ids
        },
        ssh_username:           @aws_ssh_user,
        image_id:               @image_id,
        use_private_ip_for_ssh: @use_private_ip_for_ssh
      }

      # Add any optional machine options
      require 'chef/mixin/deep_merge'
      master_template = Chef::Mixin::DeepMerge.hash_only_merge(
        master_template,
        bootstrap_options: { subnet_id: @subnet_id }
      ) if @subnet_id
      master_template
    end

    def vagrant_template
      master_template = {
        convergence_options: {
          bootstrap_proxy: @bootstrap_proxy,
          chef_config: @chef_config,
          chef_version: @chef_version,
          install_sh_path: @install_sh_path
        },
        vagrant_options: {
          'vm.box' => @vm_box,
          'vm.box_url' => @image_url,
          'vm.hostname' => @vm_hostname
        },
        vagrant_config: @vagrant_config, # Be sure config includes cpu, memory
        transport_options: {
          options: {
            prefix: @prefix
          }
        },
        use_private_ip_for_ssh: @use_private_ip_for_ssh
      }
      master_template
    end
    # rubocop:enable MethodLength

    def pipeline_mach_opts
      return @pipeline_mach_opts if @pipeline_mach_opts
      {}
    end

    def topology_list_for_stage(stage)
      return @acceptance_topologies if stage == 'acceptance'
      return @union_topologies if stage == 'union'
      return @rehearsal_topologies if stage == 'rehearsal'
      return @delivered_topologies if stage == 'delivered'
      []
    end

    def topology_list_for_pipeline
      return @pipeline_topologies if @pipeline_topologies
      []
    end
  end
end
