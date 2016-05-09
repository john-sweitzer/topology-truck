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
require 'chef/data_bag_item'
require_relative './node'

class Topo
  # Handle config.json for topology-truck
  class ConfigurationParameter
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
        raw_data['name'] = item if raw_data # Restore name attribute because of chef bug
        topo = Topo::Topology.new(name, raw_data.to_hash) if raw_data
      rescue Net::HTTPServerException => e
        raise unless e.to_s =~ /^404/
      end
      topo
    end

    def initialize(raw_data, stage = 'acceptance')
     
        @raw_data = raw_data['topology-truck'] || {}
     
     # Do we have pipeline details....
        if @raw_data.pipeline
            @driver = @raw_data['pipeline']['driver'] || ''
            if @driver
                @driver_type = driver.split(":",2)[0]
            else
                @driver_type = "default"
            end
            # Machine options in the ./delivery/config.json are options for the pipeline
            @pipeline_machine_options = @raw_data['pipeline']['machine_options'] || {}
        else
            Chef::Log.warn("Unable to find configuration details for topology-truck so cannot deploy topologies")
        end
      
      
      # Do we have stages detail...
      if @raw_data['stages']
          stage_details = @raw_data['stages'] || {}
          @acceptance_topologies    = stage_details['acceptance']['topologies'] || [] if stage_details['acceptance']
          @union_topologies         = stage_details['union']['topologies'] || [] if stage_details['union']
          @rehearsal_topologies      = stage_details['rehearsal']['topologies'] || [] if stage_details['rehearsal']
          @delivered_topologies     = stage_details['delivered']['topologies'] || [] if stage_details['delivered']
          
          @pipeline_topologies =    @acceptance_topologies +
                                    @union_topologies +
                                    @rehearsal_topologies +
                                    @delivered_topologies
      end


     # Do we have topologies detail...
    if @raw_data['topologies']
        
        
    end


      ############### Temporary code until we decide how to prime intitial value
      @ssh_user = 'vagrant'
      @ssh_user_pwd = 'vagrant'
      @chef_version = '12.8.1'
      
      
    end

    def driver
            return @driver if @driver
            'default'
    end


    def driver_type
      return @driver_type if @driver_type
      'default'
    end

    # @treturns machine option template based on driver type...
    # These templates are derived from patterns in Chef's Delivery-Cluster cookbook...
    def machine_options
        master_template = {}
        
        master_template = 
        {
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

        } if driver_type == 'aws'

        # Add any optional machine options
        require 'chef/mixin/deep_merge' if driver_type == 'aws'
        opts = Chef::Mixin::DeepMerge.hash_only_merge(opts, bootstrap_options: { subnet_id: @subnet_id }) if @subnet_id && driver_type == 'aws'


        master_template = 
        {
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

        } if driver_type == 'vagrant'


       master_template = 
       {
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

              } if driver_type == 'ssh'


        master_template
    end

    def pipeline_machine_options
            return @pipeline_machine_options if @pipeline_machine_options
            {}
    end

    def topologyList
            return @topologies if @topologies
            []
    end

    def topologyListForStage(stage)
        return @acceptance_topologies if stage == 'acceptance'
        return @union_topologies if stage == 'union'
        return @rehearsal_topologies if stage == 'rehearsal'
        return @delivered_topologies if stage == 'delivered'
        []
    end

    def topologyListForPipeline
        return @pipeline_topologies if @pipeline_topologies
        []
    end

  end
end
