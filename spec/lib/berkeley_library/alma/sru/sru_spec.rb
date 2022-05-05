require 'spec_helper'

module BerkeleyLibrary
  module Alma
    describe SRU do
      before { Config.default! }
      after { Config.send(:clear!) }

      describe :get_marc_records do
        describe 'unpaginated' do
          let(:mms_ids) { %w[991005668209706532 991005668359706532] }

          before do
            sru_query_value = mms_ids.map { |id| RecordId.parse(id) }.map(&:sru_query_value).join(' or ')
            sru_query_uri = SRU.sru_query_uri(sru_query_value)
            stub_request(:get, sru_query_uri).to_return(body: File.read('spec/data/availability-sru.xml'))
          end

          it 'returns all MARC records' do
            reader = SRU.get_marc_records(*mms_ids)
            marc_records = reader.to_a
            expect(marc_records.size).to eq(mms_ids.size)
            expect(marc_records.map(&:record_id)).to contain_exactly(*mms_ids)
          end
        end

        describe 'paginated' do
          let(:mms_ids) do
            %w[
              991005668209706532
              991005668359706532
              991005930379706532
              991005931249706532
              991007853589706532
              991007902439706532
              991007903029706532
              991008363529706532
              991008364649706532
              991008401919706532
              991008402049706532
              991008718379706532
              991008719659706532
              991008719819706532
              991009071149706532
            ]
          end

          let(:sru_query_value) { mms_ids.map { |id| RecordId.parse(id) }.map(&:sru_query_value).join(' or ') }
          let(:query_uri_page_1) { SRU.sru_query_uri(sru_query_value) }
          let(:query_uri_page_2) { BerkeleyLibrary::Util::URIs.append(query_uri_page_1, '&startRecord=11') }

          before do
            stub_request(:get, query_uri_page_1).to_return(body: File.read('spec/data/availability-sru-page-1.xml'))
          end

          it 'returns all the MARC records' do
            stub_request(:get, query_uri_page_2).to_return(body: File.read('spec/data/availability-sru-page-2.xml'))

            reader = SRU.get_marc_records(*mms_ids)
            marc_records = reader.to_a
            expect(marc_records.size).to eq(mms_ids.size)
            expect(marc_records.map(&:record_id)).to contain_exactly(*mms_ids)
          end

          it 'does not freeze records by default' do
            stub_request(:get, query_uri_page_2).to_return(body: File.read('spec/data/availability-sru-page-2.xml'))

            reader = SRU.get_marc_records(*mms_ids)
            reader.to_a.each do |record|
              expect(record.frozen?).to eq(false)
            end
          end

          it 'can freeze records' do
            stub_request(:get, query_uri_page_2).to_return(body: File.read('spec/data/availability-sru-page-2.xml'))

            reader = SRU.get_marc_records(*mms_ids, freeze: true)
            reader.to_a.each do |record|
              expect(record.frozen?).to eq(true)
            end
          end

          it 'is lazy' do
            reader = SRU.get_marc_records(*mms_ids)
            marc_records = reader.take(10).to_a
            expect(marc_records.size).to eq(10)
            retrieved_ids = marc_records.map(&:record_id).uniq
            expect(retrieved_ids.size).to eq(10)

            # order is not guaranteed, so we don't necessarily get the first 10
            retrieved_ids.each { |id| expect(mms_ids).to include(id) }
          end

        end
      end
    end
  end
end
