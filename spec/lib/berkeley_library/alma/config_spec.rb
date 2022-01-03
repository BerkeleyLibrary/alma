require 'spec_helper'
require 'uri'
require 'ostruct'

module BerkeleyLibrary
  module Alma
    describe Config do

      after(:each) do
        Config.send(:clear!)
      end

      describe :alma_sru_host= do
        it 'sets the hostname' do
          expected_host = 'alma.example.org'
          Config.alma_sru_host = expected_host
          expect(Config.alma_sru_host).to eq(expected_host)
        end
      end

      describe :alma_institution_code= do
        it 'sets the Alma institution code' do
          expected_code = '01UCS_BER'
          Config.alma_institution_code = expected_code
          expect(Config.alma_institution_code).to eq(expected_code)
        end
      end

      describe :alma_sru_base_uri do
        it 'generates the base URI from the SRU host and institution code' do
          expected_host = 'alma.example.org'
          Config.alma_sru_host = expected_host

          expected_code = '01UCS_BER'
          Config.alma_institution_code = expected_code

          base_uri = Config.alma_sru_base_uri
          expect(base_uri.host).to eq(expected_host)
          expect(base_uri.path).to end_with("/#{expected_code}")
        end

        it 'requires both the SRU host and institution code to be set' do
          expect { Config.alma_sru_base_uri }.to raise_error(ArgumentError)

          Config.alma_sru_host = 'alma.example.org'
          Config.alma_institution_code = '01UCS_BER'

          Config.alma_sru_base_uri
        end
      end

      describe 'with Rails config' do
        attr_reader :rails_config

        before(:each) do
          @rails_config = OpenStruct.new

          application = double(Object)
          allow(application).to receive(:config).and_return(rails_config)

          rails = double(Object)
          allow(rails).to receive(:application).and_return(application)

          Object.const_set(:Rails, rails)
        end

        after(:each) do
          Object.send(:remove_const, :Rails)
        end

        describe :alma_sru_base_uri do
          it 'generates the base URI from the SRU host and institution code' do
            expected_host = 'alma.example.org'
            rails_config.alma_sru_host = expected_host

            expected_code = '01UCS_BER'
            rails_config.alma_institution_code = expected_code

            base_uri = Config.alma_sru_base_uri
            expect(base_uri.host).to eq(expected_host)
            expect(base_uri.path).to end_with("/#{expected_code}")
          end
        end
      end
    end
  end
end
