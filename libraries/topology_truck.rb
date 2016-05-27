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
#
# rubocop:disable LineLength
# rubocop:disable ClassLength
# rubocop:disable HashSyntax

require 'chef/data_bag_item'
require_relative './node'

class TopologyTruck
  # Handle config.json for topology-truck
  class ConfigParms
    @stage_topologies = {}
    @topos = {}
    @ssh_private_key_path = nil
    @ssh_key = nil
    @any_ssh_drivers = false
    @any_aws_drivers = false

    # CLASS METHODS - START..

    # ssh_private_key_path =
    #         File.join(node['delivery']['workspace']['cache'],'.ssh')
    def self.ssh_private_key_path(file_name)
      unless @ssh_private_key_path
        @ssh_private_key_path = File.join(file_name, '.ssh')
        return {} unless @ssh_private_key_path
      end
      @ssh_private_key_path
    end

    # ssh_key=encrypted_data_bag_item_for_environment(
    #  'provisioning-data',
    #  'ssh_key'
    #  )
    def self.ssh_key(node)
      unless @ssh_key
        @ssh_key = Chef::Sugar::DataBag.encrypted_data_bag_item_for_environment(
          node,
          'provisioning-data',
          'ssh_key'
        )
        return {} unless @ssh_key
      end
      @ssh_key
    end
    # CLASS METHOD - END...

    def initialize(raw_data)
      @raw_data = raw_data['topology-truck'] || raw_data['topology_truck'] || {}
      @has_driver = false
      capture_pipeline_details
      capture_stage_details
      capture_topology_details

      set_ssh_machine_parms
      set_aws_machine_parms
    end

    def set_aws_machine_parms
      # TODO: ############## Temporary code until we decide how to prime initial value
      @instance_type = 't2.micro'
      # @key_name,
      @security_group_ids = ['sg-ecaf5b89']
      @aws_ssh_user = 'ubuntu'
      @image_id = 'ami-c94856a8'
      # @use_private_ip_for_ssh
      @subnet_id = 'subnet-bb898bcf'
    end

    def set_ssh_machine_parms
      # TODO: ############## Temporary code until we decide how to prime initial value
      @ssh_user = 'vagrant'
      @ssh_user_pwd = 'vagrant'
      @chef_version = '12.8.1'
    end

    # Extract the pipeline options from the config.json details
    def capture_pipeline_details
      clause = @raw_data['pipeline']
      @pl_level = true if clause
      capture_pipeline_driver(clause)
      capture_pipeline_driver_type(clause)
      capture_pipeline_machine_options(clause)
    end

    def capture_pipeline_driver(clause)
      @pl_driver = '_unspecified_' unless clause
      unless @pl_driver == '_unspecified_'
        @pl_driver = clause['driver'] || '_unspecified_'
        @has_pl_driver = true if clause['driver']
      end
    end

    def capture_pipeline_driver_type(clause)
      @pl_driver_type = '_unspecified_' unless clause
      unless @pl_driver_type == '_unspecified_'
        temp = clause['driver'] || '_unspecified_'
        @pl_driver_type = temp.split(':', 2)[0]
        @any_aws_drivers = true if @pl_driver_type == 'aws'
        @any_ssh_drivers = true if @pl_driver_type == 'ssh'
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
      capture_stage_driver_details(clause)
      capture_stage_driver_type_details(clause)
      capture_stage_machine_options(clause)
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

    def capture_stage_driver_details(clause)
      @acceptance_driver  = extract_stage_driver(clause, 'acceptance')
      @union_driver       = extract_stage_driver(clause, 'union')
      @rehearsal_driver   = extract_stage_driver(clause, 'rehearsal')
      @delivered_driver   = extract_stage_driver(clause, 'delivered')
    end

    def extract_stage_driver(clause, stage)
      # use pipeline driver details if there are no stage level details...
      return @pl_driver unless clause
      return @pl_driver unless clause[stage]
      return @pl_driver_type unless clause[stage]['driver']
      # we have stage level driver details...
      @has_st_driver = true
      clause[stage]['driver']
    end

    def capture_stage_driver_type_details(clause)
      @acceptance_driver_type  = extract_stage_driver_type(clause, 'acceptance')
      @union_driver_type       = extract_stage_driver_type(clause, 'union')
      @rehearsal_driver_type   = extract_stage_driver_type(clause, 'rehearsal')
      @delivered_driver_type   = extract_stage_driver_type(clause, 'delivered')
    end

    def extract_stage_driver_type(clause, stage)
      # use pipeline driver details if there are no stage level details...
      return @pl_driver_type unless clause
      return @pl_driver_type unless clause[stage]
      return @pl_driver_type unless clause[stage]['driver']
      # we have stage level driver details...
      temp = clause[stage]['driver'].split(':', 2)[0]
      @any_aws_drivers = true if temp == 'aws'
      @any_ssh_drivers = true if temp == 'ssh'
      temp
    end

    def capture_stage_machine_options(clause)
      @acceptance_machine_options  = extract_machine_options(clause, 'acceptance')
      @union_machine_options       = extract_machine_options(clause, 'union')
      @rehearsal_machine_options   = extract_machine_options(clause, 'rehearsal')
      @delivered_machine_options   = extract_machine_options(clause, 'delivered')
    end

    def extract_machine_options(clause, stage)
      return @pl_machine_options unless clause
      return @pl_machine_options unless clause[stage]
      return @pl_machine_options unless clause[stage]['machine_options']
      clause[stage]['machine_options'] || {}
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
    def extract_machine_options_list(opt_hash)
      list = []
      list = aws_machine_options_list(opt_hash) if pl_driver_type == 'aws'
      list = ssh_machine_options_list(opt_hash) if pl_driver_type == 'ssh'
      list
    end

    # rubocop:disable MethodLength
    # rubocop:disable CyclomaticComplexity
    # rubocop:disable PerceivedComplexity
    # rubocop:disable AbcSize
    # @returns list of machine options found in the hash
    def aws_machine_options_list(opt_hash)
      list = []
      if opt_hash['convergence_options']
        if opt_hash['convergence_options']['bootstrap_proxy']
          list << { convergence_options: { bootstrap_proxy: opt_hash['convergence_options']['bootstrap_proxy'] } }
        end
        if opt_hash['convergence_options']['chef_config']
          list << { convergence_options: { chef_config: opt_hash['convergence_options']['chef_config'] } }
        end
        if opt_hash['convergence_options']['chef_version']
          list << { convergence_options: { chef_version: opt_hash['convergence_options']['chef_version'] } }
        end
        if opt_hash['convergence_options']['install_sh_path']
          list << { convergence_options: { install_sh_path: opt_hash['convergence_options']['install_sh_path'] } }
        end
      end
      if opt_hash['bootstrap_options']
        if opt_hash['bootstrap_options']['instance_type']
          list << { bootstrap_options: { instance_type: opt_hash['bootstrap_options']['instance_type'] } }
        end
        if opt_hash['bootstrap_options']['key_name']
          list << { bootstrap_options: { key_name: opt_hash['bootstrap_options']['key_name'] } }
        end
        if opt_hash['bootstrap_options']['security_group_ids']
          list << { bootstrap_options: { security_group_id: opt_hash['bootstrap_options']['security_group_id'] } }
        end
      end

      list << { ssh_username: opt_hash['ssh_username'] }                             if opt_hash['ssh_username']
      list << { image_id: opt_hash['image_id'] }                                     if opt_hash['image_id']
      list << { use_private_ip_for_ssh: opt_hash['use_private_ip_for_ssh'] }         if opt_hash['use_private_ip_for_ssh']
      list << { transport_address_location: opt_hash['transport_address_location'] } if opt_hash['transport_address_location']

      list
    end

    # @returns list of machine options found in opt_hash
    def ssh_machine_options_list(opt_hash)
      list = []
      if opt_hash[:convergence_options]
        if opt_hash[:convergence_options][:bootstrap_proxy]
          list << { convergence_options: { bootstrap_proxy: opt_hash[:convergence_options][:bootstrap_proxy] } }
        end
        if opt_hash[:convergence_options][:chef_config]
          list << { convergence_options: { chef_config: opt_hash[:convergence_options][:chef_config] } }
        end
        if opt_hash[:convergence_options][:chef_version]
          list << { convergence_options: { chef_version: opt_hash[:convergence_options][:chef_version] } }
        end
        if opt_hash[:convergence_options][:install_sh_path]
          list << { convergence_options: { install_sh_path: opt_hash[:convergence_options][:install_sh_path] } }
        end
      end
      if opt_hash[:transport_options]
        if opt_hash[:transport_options][:username]
          list << { transport_options: { username: opt_hash[:transport_options][:username] } }
        end
        if opt_hash[:transport_options][:ssh_options]
          if opt_hash[:transport_options][:ssh_options][:user]
            list << { transport_options: { ssh_options: { user: opt_hash[:transport_options][:ssh_options][:user] } } }
          end
          if opt_hash[:transport_options][:ssh_options][:password]
            list << { transport_options: { ssh_options: { password: opt_hash[:transport_options][:ssh_options][:password] } } }
          end
          if opt_hash[:transport_options][:ssh_options][:keys]
            list << { transport_options: { ssh_options: { keys: opt_hash[:transport_options][:ssh_options][:keys] } } }
          end
        end
        if opt_hash[:transport_options][:options]
          if opt_hash[:transport_options][:options][:prefix]
            list << { transport_options: { options: { prefex: opt_hash[:transport_options][:options][:prefix] } } }
          end
        end
      end
      list
    end
    # rubocop:enable MethodLength

    # @returns machine option template based on driver type...
    # Templates are derived from patterns in Chef's Delivery-Cluster cookbook...
    def machine_options
      master_template = aws_template if pl_driver_type == 'aws'
      master_template = ssh_template if pl_driver_type == 'ssh'
      master_template || {}
    end

    def machine_options_template
      machine_options
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
        use_private_ip_for_ssh: @use_private_ip_for_ssh,
        transport_address_location: 'public_ip' #:public_ip
      }

      # Add any optional machine options
      require 'chef/mixin/deep_merge'
      master_template = Chef::Mixin::DeepMerge.hash_only_merge(
        master_template,
        bootstrap_options: { subnet_id: @subnet_id }
      ) if @subnet_id
      master_template
    end
    # rubocop:enable MethodLength

    def drivers?
      @pl_driver || @st_driver || @tp_driver
    end

    # Return true is 'aws" was specified at pl, st, or tp levels
    def any_aws_drivers?
      return false unless @any_aws_drivers
      @any_aws_drivers
    end

    # Return true if 'ssh" was specified at pl, st, or tp levels
    def any_ssh_drivers?
      return false unless @any_ssh_drivers
      @any_ssh_drivers
    end

    def pl_level?
      return true if @pl_level
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
      return true if @st_level
      false
    end

    def st_driver(st)
      return @acceptance_driver  if st == 'acceptance'
      return @union_driver       if st == 'union'
      return @rehearsal_driver   if st == 'rehearsal'
      return @delivered_driver   if st == 'delivered'
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
      return @acceptance_machine_options  if st == 'acceptance'
      return @union_machine_options       if st == 'union'
      return @rehearsal_machine_options   if st == 'rehearsal'
      return @delivered_machine_options   if st == 'delivered'
      { 'none_specified' => true }
    end

    def st_topologies(st)
      return @acceptance_topologies if st == 'acceptance'
      return @union_topologies      if st == 'union'
      return @rehearsal_topologies if st == 'rehearsal'
      return @delivered_topologies if st == 'delivered'
      [{ 'none_specified_for_stage' => st }]
    end

    def tp_level?
      return @tp_level if @tp_level
      false
    end

    def tp_driver(tp)
      return { 'none_specified' => true } if tp == 'acceptance'
      return { 'none_specified' => true } if tp == 'union'
      return { 'none_specified' => true } if tp == 'rehearsal'
      return { 'none_specified' => true } if tp == 'delivered'
      { 'none_specified' => true }
    end

    def tp_driver_type(tp)
      return { 'none_specified' => true } if tp == 'acceptance'
      return { 'none_specified' => true } if tp == 'union'
      return { 'none_specified' => true } if tp == 'rehearsal'
      return { 'none_specified' => true } if tp == 'delivered'
      { 'none_specified' => true }
    end

    def tp_has_drivers?(_tp)
      false
    end

    def tp_calc_driver_type(_tp)
      pl_driver
    end

    def tp_machine_options(tp)
      return { :bootstrap_options => { :instance_type => 'INSTANCE_TYPE', :key_name => 'KEY_NAME', :security_group_ids => 'SECURITY_GROUP_IDS' } } if tp == 'test'

      { 'none_specified' => true }
    end

    def tp_calc_machine_options(_tp)
      pl_machine_options
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
