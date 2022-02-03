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

def sru_url_for(record_id)
  sru_url_base = 'https://berkeley.alma.exlibrisgroup.com/view/sru/01UCS_BER?version=1.2&operation=searchRetrieve&query='

  if BerkeleyLibrary::Alma::Constants::ALMA_RECORD_RE =~ record_id
    "#{sru_url_base}alma.mms_id%3D#{record_id}"
  elsif BerkeleyLibrary::Alma::Constants::MILLENNIUM_RECORD_RE =~ record_id
    full_bib_number = BerkeleyLibrary::Alma::BibNumber.new(record_id).to_s
    "#{sru_url_base}alma.local_field_996%3D#{full_bib_number}"
  else
    raise ArgumentError, "Unknown record ID type: #{record_id}"
  end
end

def sru_data_path_for(record_id)
  "spec/data/#{record_id}-sru.xml"
end

def stub_sru_request(record_id)
  sru_url = sru_url_for(record_id)
  marc_xml_path = sru_data_path_for(record_id)

  stub_request(:get, sru_url).to_return(status: 200, body: File.read(marc_xml_path))
end
