require 'spec_helper'

module BerkeleyLibrary
  module Alma
    describe BarCode do
      before do
        BerkeleyLibrary::Alma.configure do
          Config.alma_sru_host = 'berkeley.alma.exlibrisgroup.com'
          Config.alma_institution_code = '01UCS_BER'
          Config.alma_primo_host = 'search.library.berkeley.edu'
          Config.alma_permalink_key = 'iqob43'
        end
      end

      after do
        BerkeleyLibrary::Alma::Config.send(:clear!)
      end

      describe :new do
        bad_barcode = 1234
        it "raises an error for input that's not an string" do
          expect { BarCode.new(bad_barcode) }.to raise_error(ArgumentError), "#{bad_barcode}: No error raised for #{bad_barcode}"
        end
      end

      describe :marc_record do
        it 'returns the MARC record' do
          barcode_id = 'C084093187'
          stub_sru_request('alma.barcode', barcode_id)

          barcode = BerkeleyLibrary::Alma::BarCode.new(barcode_id)
          marc_record = barcode.get_marc_record
          expect(marc_record).not_to be_nil
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

          barcode_id = '991054360089706532doesntexist'
          sru_url = sru_url_for('alma.barcode', barcode_id)
          stub_request(:get, sru_url).to_return(status: 200, body: empty_sru_response)

          barcode = BarCode.new(barcode_id)
          marc_record = barcode.get_marc_record
          expect(marc_record).to be_nil
        end

        it 'returns nil for an HTTP error response' do
          barcode_id = '991054360089706532934j3h'
          sru_url = sru_url_for('alma.barcode', barcode_id)
          stub_request(:get, sru_url).to_return(status: 404)

          barcode = BarCode.new(barcode_id)
          marc_record = barcode.get_marc_record
          expect(marc_record).to be_nil
        end
      end
    end
  end
end
