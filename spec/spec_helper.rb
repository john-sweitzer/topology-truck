# Prime helper with sample code from delivery-truck
# rubocop:disable LineLength

require 'chefspec'
require 'chefspec/berkshelf'

TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

# Require all our libraries
Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }

# Declare common let declarations
module GlobalLetSymbols
  extend RSpec::SharedContext
  let(:one_changed_cookbook) do
    [
      double(
        'delivery sugar cookbook',
        name: 'julia',
        path: '/tmp/repo/cookbooks/julia',
        version: '0.1.0'
      )
    ]
  end

  let(:two_changed_cookbooks) do
    [
      double('delivery sugar cookbook', name: 'julia', path: '/tmp/repo/cookbooks/julia', version:  '0.1.0'),
      double('delivery sugar cookbook', name: 'gordon', path: '/tmp/repo/cookbooks/gordon', version: '0.2.0')
    ]
  end

  let(:no_changed_cookbooks) { [] }
end

RSpec.configure do |config|
  config.include GlobalLetSymbols
  config.filter_run_excluding ignore: true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # Specify the operating platform to mock Ohai data from (default: nil)
  config.platform = 'ubuntu'

  # Specify the operating version to mock Ohai data from (default: nil)
  config.version = '12.04'
end
