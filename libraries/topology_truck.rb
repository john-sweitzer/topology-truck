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
    @topos = {}
    @ssh_private_key_path = nil 
# CLASS METHODS - START..
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
    
    # ssh_private_key_path = File.join(node['delivery']['workspace']['cache'], '.ssh')
    def self.ssh_private_key_path(file_name)
      unless @ssh_private_key_path
        @ssh_private_key_path = File.join(file_name, '.ssh')
        return {} unless @ssh_private_key_path
      end
      @ssh_private_key_path
    end
# CLASS METHOD - END...
    
    
    def initialize(raw_data, _stage = 'acceptance')
      @raw_data = raw_data['topology-truck'] || raw_data['topology_truck'] || {}
      capture_pipeline_details
      capture_stage_details
      capture_topology_details

      set_ssh_machine_parms
      set_aws_machine_parms
    end

    def set_aws_machine_parms
      ############### Temporary code until we decide how to prime initial value
      @instance_type = 't2.micro'
      # @key_name,
      @security_group_ids = ['sg-ecaf5b89']
      @aws_ssh_user = 'ubuntu'
      @image_id = 'ami-c94856a8'
      # @use_private_ip_for_ssh
      @subnet_id = 'subnet-bb898bcf'
    end

    def set_ssh_machine_parms
      ############### Temporary code until we decide how to prime initial value
      @ssh_user = 'vagrant'
      @ssh_user_pwd = 'vagrant'
      @chef_version = '12.8.1'
    end

    # Extract the pipeline options from the config.json details
    def capture_pipeline_details
      clause = @raw_data['pipeline']
      @pl_level = true if clause
      capture_pipeline_driver_type(clause)
      capture_pipeline_machine_options(clause)
    end

    def capture_pipeline_driver_type(clause)
      @pl_driver_type = '_unspecified_'
      @pl_driver = '_unspecified_' unless clause
      unless @pl_driver == '_unspecified_'
        @pl_driver = clause['driver'] || '_unspecified_'
        @pl_driver_type = @pl_driver.split(':', 2)[0]
      end
    end

    def capture_pipeline_machine_options(clause)
      return {} unless clause
      @pl_machine_options = clause['machine_options'] || {}
    end

    #
    # Extract stage details from the config.json file...
    #
    def capture_stage_details
      clause = @raw_data['stages']
      @st_level = true if clause
      capture_stage_topology_details(clause)
      capture_stage_driver_type_details(clause)
    end

    def capture_stage_topology_details(clause)
      @acceptance_topologies  = extract_topology(clause, 'acceptance')
      @union_topologies       = extract_topology(clause, 'union')
      @rehearsal_topologies   = extract_topology(clause, 'rehearsal')
      @delivered_topologies   = extract_topology(clause, 'delivered')
      @pl_topologies = @acceptance_topologies + @union_topologies +
                       @rehearsal_topologies + @delivered_topologies
    end

    def extract_topology(clause, stage)
      return [] unless clause
      return [] unless clause[stage]
      clause[stage]['topologies'] || []
    end

    def capture_stage_driver_type_details(clause)
      @acceptance_driver_type  = extract_driver_type(clause, 'acceptance')
      @union_driver_type       = extract_driver_type(clause, 'union')
      @rehearsal_driver_type   = extract_driver_type(clause, 'rehearsal')
      @delivered_driver_type   = extract_driver_type(clause, 'delivered')
    end

    def extract_driver_type(clause, stage)
      return @pl_driver_type unless clause
      return @pl_driver_type unless clause[stage]
      return @pl_driver_type unless clause[stage]['driver']
      clause[stage]['driver'].split(':', 2)[0]
    end

    #
    #
    #
    def capture_topology_details
      # Do we have topologies detail...
      clause = @raw_data['topologies']
      @tp_level = true if clause
    end

    # @returns machine option template based on driver type...
    # Templates are derived from patterns in Chef's Delivery-Cluster cookbook...
    def machine_options
      master_template = {}
      master_template = aws_template if pl_driver_type == 'aws'
      master_template = vagrant_template if pl_driver_type == 'vagrant'
      master_template = ssh_template if pl_driver_type == 'ssh'
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

    def pl_level?
      return @pl_level if @pl_level
      false
    end

    def pl_driver
      return @pl_driver if @pl_driver
      '_unspecified_'
    end

    def pl_driver_type
      return @pl_driver_type if @pl_driver_type
      '_unspecified_'
    end

    def pl_machine_options
      return @pl_machine_options if @pl_machine_options
      {}
    end

    def pl_topologies
      return @pl_topologies if @pl_topologies
      []
    end

    def st_level?
      return @st_level if @st_level
      false
    end

    def st_driver(st)
      return { 'none_specified' => true } if st == 'acceptance'
      return { 'none_specified' => true } if st == 'union'
      return { 'none_specified' => true } if st == 'rehearsal'
      return { 'none_specified' => true } if st == 'delivered'
      { 'none_specified' => true }
    end

    def st_driver_type(st)
      return @acceptance_driver_type  if st == 'acceptance'
      return @union_driver_type       if st == 'union'
      return @rehearsal_driver_type   if st == 'rehearsal'
      return @delivered_driver_type   if st == 'delivered'
      { 'none_specified' => true }
    end

    def st_machine_options(st)
      return { 'none_specified' => true } if st == 'acceptance'
      return { 'none_specified' => true } if st == 'union'
      return { 'none_specified' => true } if st == 'rehearsal'
      return { 'none_specified' => true } if st == 'delivered'
      { 'none_specified' => true }
    end

    def st_topologies(st)
      return @acceptance_topologies if st == 'acceptance'
      return @union_topologies if st == 'union'
      return @rehearsal_topologies if st == 'rehearsal'
      return @delivered_topologies if st == 'delivered'
      [{ 'none_specified_for_stage' => st }]
    end

    def tp_level?
      return @tp_level if @tp_level
      false
    end

    def tp_driver(st)
      return { 'none_specified' => true } if st == 'acceptance'
      return { 'none_specified' => true } if st == 'union'
      return { 'none_specified' => true } if st == 'rehearsal'
      return { 'none_specified' => true } if st == 'delivered'
      { 'none_specified' => true }
    end

    def tp_driver_type(st)
      return { 'none_specified' => true } if st == 'acceptance'
      return { 'none_specified' => true } if st == 'union'
      return { 'none_specified' => true } if st == 'rehearsal'
      return { 'none_specified' => true } if st == 'delivered'
      { 'none_specified' => true }
    end

    def tp_machine_options(st)
      return { 'none_specified' => true } if st == 'acceptance'
      return { 'none_specified' => true } if st == 'union'
      return { 'none_specified' => true } if st == 'rehearsal'
      return { 'none_specified' => true } if st == 'delivered'
      { 'none_specified' => true }
    end

    def tp_topologies(st)
      return @acceptance_topologies if st == 'acceptance'
      return @union_topologies      if st == 'union'
      return @rehearsal_topologies  if st == 'rehearsal'
      return @delivered_topologies  if st == 'delivered'
      [{ 'none_specified_for_stage' => st }]
    end
  end
end
