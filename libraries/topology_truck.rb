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
    # TODO: Should these be class or instance variables?
    # CLASS Variables - START

    @stage_topologies = {}
    @topos = {}
    @ssh_private_key_path = nil
    @ssh_key = nil
    @any_ssh_drivers = false
    @any_aws_drivers = false

    # CLASS Variables - End

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

    def initialize(raw_data, node)
      @raw_data = raw_data['topology-truck'] || raw_data['topology_truck'] || {}

      # There are global variables for an instance of this class
      initialize_instance_variables

      # Load 'machine_options' attributes into local variables so they can be
      # used as defaults in the machine_options templates...
      prime_ssh_machine_parms(node)
      prime_aws_machine_parms(node)

      # Capture details move from the most global to the most local..,
      capture_pipeline_details
      capture_stage_details
      capture_topology_details
    end

    # ...
    def initialize_instance_variables
      @pl_level = false
      @has_driver = false
      @has_st_driver = false
      @has_pl_driver = false
      @any_aws_drivers = false
      @any_ssh_drivers = false
      @tp_map = {}
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
      if clause
        @pl_driver = clause['driver'] || '_unspecified_'
        @has_pl_driver = true if clause['driver']
      else
        @pl_driver = '_unspecified_'
      end
    end

    def capture_pipeline_driver_type(clause)
      if clause
        temp = clause['driver'] || '_unspecified_'
        @pl_driver_type = temp.split(':', 2)[0]
        @any_aws_drivers = true if @pl_driver_type == 'aws'
        @any_ssh_drivers = true if @pl_driver_type == 'ssh'
      else
        @pl_driver_type = '_unspecified_'
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
      capture_stage_driver_details(clause)
      capture_stage_driver_type_details(clause)
      capture_stage_machine_options(clause)
      capture_stage_topology_details(clause)
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
      list = clause[stage]['topologies'] || []
      list.each do |tp|
        construct_topology(tp, stage)
      end
      list
    end

    def construct_topology(tp, stage)
      #
      drv = st_driver(stage)
      drvt = drv.split(':', 2)[0]
      #
      mo = calculate_topology_machine_options(drvt, stage)
      #
      @tp_map[tp] = { 'stage' => stage, 'driver' => drv, 'driver_type' => drvt, 'machine_options' => mo }
    end

    def calculate_topology_machine_options(drvt, stage)
      # start with the template for the current driver...
      mo = machine_options_template(drvt)
      # add details supplied at the pl, st, and tp levels
      mo = add_machine_options(mo, @pl_machine_options, drvt) if @pl_driver_type == drvt
      mo = add_machine_options(mo, st_machine_options(stage), drvt) if st_driver_type(stage) == drvt
      mo
    end

    def add_machine_options(mo1, mo2, drvt)
      #
      list = []
      list = aws_machine_options_list(mo2) if drvt == 'aws'
      list = ssh_machine_options_list(mo2) if drvt == 'ssh'
      mo_template = mo1.clone
      #
      list.each do |item|
        # Add any optional machine options
        require 'chef/mixin/deep_merge'
        mo_template = Chef::Mixin::DeepMerge.hash_only_merge(mo_template, item)
        mo_template
      end
      mo_template
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
      return @pl_driver unless clause[stage]['driver']
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
      return {} unless clause
      return {} unless clause[stage]
      return {} unless clause[stage]['machine_options']
      clause[stage]['machine_options']
    end

    #
    #
    #
    def capture_topology_details
      # Do we have topologies detail...
      clause = @raw_data['topologies']
      @tp_level = true if clause
      #
      clause.each do |tp_name, body|
        construct_tp_topology(tp_name, body)
      end if clause
    end

    def construct_tp_topology(tp_name, body)
      #
      Chef::Log.warn("The topology #{tp_name} must have a { stage => x } hash to be considered.") unless body['stage']
      stage = body['stage']   || '_missing_stage_'
      drv   = body['driver']  || st_driver(stage)
      drvt = drv.split(':', 2)[0]
      tp_mo = body['machine_options'] || {}
      #
      mo = calculate_tp_topology_machine_options(tp_mo, drvt, stage)
      #
      @tp_map[tp_name] = { 'stage' => stage, 'driver' => drv, 'driver_type' => drvt, 'machine_options' => mo } unless stage == '_missing_stage_'
    end

    def calculate_tp_topology_machine_options(tp_mo, drvt, stage)
      # start with the template for the current driver...
      mo = machine_options_template(drvt)
      # add details supplied at the pl, st, and tp levels
      mo = add_machine_options(mo, @pl_machine_options, drvt) if @pl_driver_type == drvt
      mo = add_machine_options(mo, st_machine_options(stage), drvt) if st_driver_type(stage) == drvt
      mo = add_machine_options(mo, tp_mo, drvt)
      mo
    end

    # @returns machine option template based on driver type...
    # Templates are derived from patterns in Chef's Delivery-Cluster cook book...
    def extract_machine_options_list(opt_hash)
      list = []
      list = aws_machine_options_list(opt_hash) if @pl_driver_type == 'aws'
      list = ssh_machine_options_list(opt_hash) if @pl_driver_type == 'ssh'
      list
    end

    # rubocop:disable MethodLength
    # rubocop:disable CyclomaticComplexity
    # rubocop:disable PerceivedComplexity
    # rubocop:disable AbcSize
    # @returns list of machine option fragments found in the hash
    def aws_machine_options_list(opt_hash)
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
      if opt_hash[:bootstrap_options]
        if opt_hash[:bootstrap_options][:instance_type]
          list << { bootstrap_options: { instance_type: opt_hash[:bootstrap_options][:instance_type] } }
        end
        if opt_hash[:bootstrap_options][:key_name]
          list << { bootstrap_options: { key_name: opt_hash[:bootstrap_options][:key_name] } }
        end
        if opt_hash[:bootstrap_options][:security_group_ids]
          list << { bootstrap_options: { security_group_id: opt_hash[:bootstrap_options][:security_group_id] } }
        end
      end

      list << { ssh_username: opt_hash[:ssh_username] }                             if opt_hash[:ssh_username]
      list << { image_id: opt_hash[:image_id] }                                     if opt_hash[:image_id]
      list << { use_private_ip_for_ssh: opt_hash[:use_private_ip_for_ssh] }         if opt_hash[:use_private_ip_for_ssh]
      list << { transport_address_location: opt_hash[:transport_address_location] } if opt_hash[:transport_address_location]

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
      master_template = aws_template if @pl_driver_type == 'aws'
      master_template = ssh_template if @pl_driver_type == 'ssh'
      master_template || {}
    end

    def machine_options_template(drv)
      template = aws_template if drv == 'aws'
      template = ssh_template if drv == 'ssh'
      template || {}
    end

    # rubocop:disable MethodLength
    def ssh_template
      master_template = {
        convergence_options: {
          bootstrap_proxy: @bootstrap_proxy,
          chef_config: @chef_config_ssh,
          chef_version: @chef_version_ssh,
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
          chef_config: @chef_config_aws,
          chef_version: @chef_version_aws,
          install_sh_path: @install_sh_path
        },
        bootstrap_options: {
          instance_type:      @instance_type,
          key_name:           @key_name,
          security_group_ids: @security_group_ids
        },
        ssh_username:           @ssh_user_aws,
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

    def prime_aws_machine_parms(node)
      # TODO: ############## Need to finish priming variables...
      # @key_name               = node['topology-truck']['pipeline']['aws']['key_name']
      @ssh_user_aws           = node['topology-truck']['pipeline']['aws']['ssh_username']
      @security_group_ids     = node['topology-truck']['pipeline']['aws']['security_group_ids']
      @image_id               = node['topology-truck']['pipeline']['aws']['image_id']
      @instance_type          = node['topology-truck']['pipeline']['aws']['instance_type']
      @subnet_id              = node['topology-truck']['pipeline']['aws']['subnet_id']
      # @                       = node['topology-truck']['pipeline']['aws']['bootstrap_proxy']
      # @chef_config_aws        = node['topology-truck']['pipeline']['aws']['chef_config']
      @chef_version_aws       = node['topology-truck']['pipeline']['aws']['chef_version']
      @use_private_ip_for_ssh = node['topology-truck']['pipeline']['aws']['use_private_ip_for_ssh']
    end

    def prime_ssh_machine_parms(node)
      # TODO: ############## need to finish priming variables...
      # @                       = node['topology-truck']['pipeline']['ssh']['key_file']
      # @                       = node['topology-truck']['pipeline']['ssh']['prefix']
      @ssh_user               = node['topology-truck']['pipeline']['ssh']['ssh_username']
      @ssh_user_pwd           = node['topology-truck']['pipeline']['ssh']['ssh_password']
      # @                       = node['topology-truck']['pipeline']['ssh']['bootstrap_proxy']
      # @chef_config_ssh        = node['topology-truck']['pipeline']['ssh']['chef_config']
      @chef_version_ssh       = node['topology-truck']['pipeline']['ssh']['chef_version']
      @use_private_ip_for_ssh = node['topology-truck']['pipeline']['ssh']['use_private_ip_for_ssh']
    end
    # rubocop:enable AbcSize

    def drivers?
      @pl_driver || @st_driver || @tp_driver
    end

    # Return true is 'aws' was specified at pl, st, or tp levels
    def any_aws_drivers?
      return false unless @any_aws_drivers
      @any_aws_drivers
    end

    # Return true if 'ssh' was specified at pl, st, or tp levels
    def any_ssh_drivers?
      return false unless @any_ssh_drivers
      @any_ssh_drivers
    end

    # Return true if 'ssh' or 'aws' was specified at pl, st, or tp levels
    def any_drivers?
      @any_ssh_drivers || @any_aws_drivers
    end

    # Return true if any machine options are specified at the pl, st, or tp levels
    def any_machine_options?
      @any_ssh_drivers || @any_aws_drivers
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
      return []                     if st == 'verify'
      return []                     if st == 'build'
      return @acceptance_topologies if st == 'acceptance'
      return @union_topologies      if st == 'union'
      return @rehearsal_topologies  if st == 'rehearsal'
      return @delivered_topologies  if st == 'delivered'

      [{ 'none_specified_for_stage' => st }]
    end

    def tp_level?
      return @tp_level if @tp_level
      false
    end

    def tp_driver(tp)
      return @tp_map[tp]['driver'] if @tp_map[tp]['driver']
      { 'none_specified' => true }
    end

    def tp_driver_type(tp)
      return @tp_map[tp]['driver_type'] if @tp_map[tp]['driver_type']
      { 'none_specified' => true }
    end

    def tp_machine_options(tp)
      return { :bootstrap_options => { :security_group_ids => 'TOPOLOGY_TEST_SECURITY_GROUP_ID' } } unless @tp_map[tp]
      return @tp_map[tp]['machine_options'] if @tp_map[tp]['machine_options']
      { 'none_specified' => true }
    end
  end
end
