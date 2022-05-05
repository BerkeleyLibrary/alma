require 'spec_helper'

module BerkeleyLibrary
  module Alma
    module SRU
      describe XMLReader do
        let(:sru_xml_1) { File.read('spec/data/availability-sru-page-1.xml') }
        let(:sru_xml_2) { File.read('spec/data/availability-sru-page-2.xml') }

        let(:reader) { XMLReader.read(sru_xml_2) }
        let(:expected_ids) { %w[991008719659706532 991005668209706532 991008363529706532 991008402049706532 991008719819706532] }

        it 'reads the records' do
          records = reader.to_a
          expect(records.size).to eq(expected_ids.size)
          expect(records.map(&:record_id)).to eq(expected_ids)
        end

        describe :new do
          it 'raises an error for unreadable sources' do
            not_xml = Object.new
            expect { XMLReader.read(not_xml) }.to raise_error(ArgumentError)
          end
        end

        describe :num_records do
          it 'returns the <numberOfRecords/> value' do
            reader.first # make sure we've gotten far enough in the doc to parse
            expect(reader.num_records).to eq(15)
          end
        end

        describe :last_record_position do
          it 'returns the (1-indexed) position of the most recent record' do
            position_base = 11
            reader.each_with_index do |_, i|
              expect(reader.last_record_position).to eq(position_base + i)
            end
          end
        end

        describe :last_record_id do
          it 'returns the ID of the most recent record' do
            reader.each do |record|
              expect(reader.last_record_id).to eq(record.record_id)
            end
          end
        end

        describe :next_record_position do
          it 'returns nil if there is no next page' do
            reader.to_a # read all records
            expect(reader.next_record_position).to be_nil
          end

          it 'returns the record position of the next page' do
            reader = XMLReader.read(sru_xml_1)
            reader.to_a # read all records
            expect(reader.next_record_position).to eq(11)
          end
        end

        describe :records_yielded do
          it 'returns the number of records yielded' do
            expect(reader.records_yielded).to eq(0)
            reader.each_with_index do |_, i|
              expect(reader.records_yielded).to eq(i)
            end
            expect(reader.records_yielded).to eq(5)
          end
        end
      end
    end
  end
end
