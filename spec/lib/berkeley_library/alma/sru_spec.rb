require 'spec_helper'

module BerkeleyLibrary
  module Alma
    describe SRU do
      before { Config.default! }
      after { Config.send(:clear!) }

      describe :get_marc_records do
        let(:mms_ids) { %w[991005668209706532 991005668359706532] }

        before do
          sru_query_value = mms_ids.map { |id| RecordId.parse(id) }.map(&:sru_query_value).join(' or ')
          sru_query_uri = SRU.sru_query_uri(sru_query_value)
          stub_request(:get, sru_query_uri).to_return(body: File.read('spec/data/availability-sru.xml'))
        end

        it 'returns the MARC records' do
          reader = SRU.get_marc_records(*mms_ids)
          expect(reader).to be_a(MARC::XMLReader)

          marc_records = reader.to_a
          expect(marc_records.size).to eq(mms_ids.size)
          expect(marc_records.map(&:record_id)).to contain_exactly(*mms_ids)
        end
      end
    end
  end
end
