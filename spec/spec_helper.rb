# ------------------------------------------------------------
# Simplecov

if ENV['COVERAGE']
  require 'colorize'
  require 'simplecov'
end

# ------------------------------------------------------------
# RSpec

require 'webmock/rspec'

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
  config.before(:each) { WebMock.disable_net_connect!(allow_localhost: true) }
  config.after(:each) { WebMock.allow_net_connect! }
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end

# ------------------------------------------------------------
# Code under test

require 'berkeley_library/alma'

# ------------------------------------------------------------
# Utility methods

def sru_url_for(index, value, max_records: 1)
  "https://berkeley.alma.exlibrisgroup.com/view/sru/01UCS_BER?version=1.2&operation=searchRetrieve&query=#{index}%3D#{value}&maximumRecords=#{max_records}"
end

def sru_data_path_for(record_id)
  "spec/data/#{record_id}-sru.xml"
end

def stub_sru_request(index, value, max_records: 1)
  sru_url = sru_url_for(index, value, max_records: max_records)
  marc_xml_path = sru_data_path_for(value)

  stub_request(:get, sru_url).to_return(status: 200, body: File.read(marc_xml_path))
end
