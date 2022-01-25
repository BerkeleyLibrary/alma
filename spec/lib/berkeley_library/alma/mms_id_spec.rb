require 'spec_helper'

module BerkeleyLibrary
  module Alma
    describe MMSID do
      before(:each) do
        BerkeleyLibrary::Alma.configure do
          Config.alma_sru_host = 'berkeley.alma.exlibrisgroup.com'
          Config.alma_institution_code = '01UCS_BER'
          Config.alma_primo_host = 'search.library.berkeley.edu'
          Config.alma_permalink_key = 'iqob43'
        end
      end

      after(:each) do
        BerkeleyLibrary::Alma::Config.send(:clear!)
      end

      describe :new do
        it "raises an error for input that's not an MMS ID" do
          bad_record_numbers = %w[
            b11082434
            (coll)12345
            99127506531
            235607980063450199
          ]

          aggregate_failures do
            bad_record_numbers.each do |bad_mms_id|
              expect { MMSID.new(bad_mms_id) }.to raise_error(ArgumentError), "#{bad_mms_id}: No error raised for #{bad_mms_id}"
            end
          end
        end
      end

      describe :to_s do
        it 'returns the MMS ID' do
          raw_mms_id = '991054360089706532'
          mms_id = MMSID.new(raw_mms_id)
          expect(mms_id.to_s).to eq(raw_mms_id)
        end
      end

      describe :berkeley? do
        it 'returns true for a Berkeley ID' do
          raw_mms_id = '991054360089706532'
          mms_id = MMSID.new(raw_mms_id)
          expect(mms_id).to be_berkeley
        end

        it 'returns false for a non-Berkeley ID' do
          raw_mms_id = '9912727694506531'
          mms_id = MMSID.new(raw_mms_id)
          expect(mms_id).not_to be_berkeley
        end
      end

      describe :marc_record do
        it 'returns the MARC record' do
          raw_mms_id = '991054360089706532'
          stub_sru_request(raw_mms_id)

          mms_id = MMSID.new(raw_mms_id)
          marc_record = mms_id.get_marc_record
          expect(marc_record).not_to be_nil
          expect(marc_record.record_id).to eq(raw_mms_id)
        end

        it 'returns nil for an empty response' do
          empty_sru_response = <<~XML.strip
            <?xml version="1.0" encoding="UTF-8"?>
            <searchRetrieveResponse>
              <version>1.2</version>
              <numberOfRecords>0</numberOfRecords>
              <records/>
            </searchRetrieveResponse>
          XML

          raw_mms_id = '991054360089706532'
          sru_url = sru_url_for(raw_mms_id)
          stub_request(:get, sru_url).to_return(status: 200, body: empty_sru_response)

          mms_id = MMSID.new(raw_mms_id)
          marc_record = mms_id.get_marc_record
          expect(marc_record).to be_nil
        end

        it 'returns nil for an HTTP error response' do
          raw_mms_id = '991054360089706532'
          sru_url = sru_url_for(raw_mms_id)
          stub_request(:get, sru_url).to_return(status: 404)

          mms_id = MMSID.new(raw_mms_id)
          marc_record = mms_id.get_marc_record
          expect(marc_record).to be_nil
        end
      end

      describe :permalink_uri do
        it 'returns the permalink' do
          raw_mms_id = '991054360089706532'
          expected_url = "https://search.library.berkeley.edu/permalink/01UCS_BER/iqob43/alma#{raw_mms_id}"

          mms_id = MMSID.new(raw_mms_id)
          expected_uri = URI.parse(expected_url)
          expect(mms_id.permalink_uri).to eq(expected_uri)
        end
      end
    end
  end
end
