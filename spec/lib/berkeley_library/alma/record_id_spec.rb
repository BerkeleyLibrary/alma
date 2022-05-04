require 'spec_helper'

module BerkeleyLibrary
  module Alma
    describe RecordId do
      describe :parse do
        it 'parses a bib number' do
          raw_bib = 'b11082434'
          bib_number = BibNumber.new(raw_bib)

          expect(RecordId.parse(raw_bib)).to eq(bib_number)
        end

        it 'parses an MMS ID' do
          raw_mms_id = '991038544199706532'
          mms_id = MMSID.new(raw_mms_id)

          expect(RecordId.parse(raw_mms_id)).to eq(mms_id)
        end

        it 'returns nil for things that are not record IDs' do
          bad_ids = %w[
            b1234567
            b123456789abcdef
            (coll)12345
            o12345678
            99127506531
            235607980063450199
          ]

          aggregate_failures do
            bad_ids.each do |bad_id|
              parsed_id = RecordId.parse(bad_id)
              expect(parsed_id).to be_nil, "Expected nil for #{bad_id}, got #{parsed_id}"
            end
          end
        end
      end

      describe 'SRU methods' do
        before { Config.default! }
        after { Config.send(:clear!) }

        describe :get_marc_xml do
          let(:record_id) { RecordId.parse('991054360089706532') }
          let(:expected_body) { File.read('spec/data/991054360089706532-sru.xml') }

          before do
            sru_query_uri = record_id.marc_uri
            stub_request(:get, sru_query_uri).to_return(body: expected_body)
          end

          it 'returns the MARC XML' do
            marc_xml = record_id.get_marc_xml
            expect(marc_xml).to eq(expected_body)
          end
        end
      end
    end
  end
end
