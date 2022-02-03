require 'spec_helper'

module BerkeleyLibrary
  module Alma
    describe BibNumber do
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

      let(:expected_check_digits_by_bib) do
        infile = 'spec/data/bibs_with_check_digits.txt'
        File.readlines(infile, chomp: true).each_with_object({}) do |bib, x|
          x[bib[0, 9]] = bib[9]
        end
      end

      describe :new do
        it "raises an error for input that's not a bib number" do
          bad_record_numbers = %w[
            b1234567
            b123456789abcdef
            (coll)12345
            o12345678
            991054360089706532
          ]

          aggregate_failures do
            bad_record_numbers.each do |bad_bib|
              expect { BibNumber.new(bad_bib) }.to raise_error(ArgumentError), "#{bad_bib}: No error raised for #{bad_bib}"
            end
          end
        end

        it 'accepts an upper-case B, but treats it as lower case' do
          raw_bib = 'B11082434'
          expected_bib = 'b110824349'
          bib_number = BibNumber.new(raw_bib)
          expect(bib_number.full_bib).to eq(expected_bib)
          expect(bib_number.to_s).to eq(expected_bib)
        end

        it 'produces the expected check digit' do
          aggregate_failures do
            expected_check_digits_by_bib.each do |bib_expected, cd_expected|
              bib_with_cd = BibNumber.new(bib_expected).to_s
              expect(bib_with_cd[0, 9]).to eq(bib_expected) # just to be sure

              cd_actual = bib_with_cd[9]
              expect(cd_actual).to eq(cd_expected), "Wrong check digit for #{bib_expected}; should be #{cd_expected}, was #{cd_actual}"
            end
          end
        end

        it 'raises an error if passed an invalid check digit' do
          aggregate_failures do
            expected_check_digits_by_bib.each do |bib, cd|
              cd_i = cd == 'x' ? 10 : cd.to_i
              bad_cd = cd_i == 0 ? 'x' : (cd_i - 1).to_s
              bad_bib = "#{bib}#{bad_cd}"
              expect { BibNumber.new(bad_bib).to_s }.to raise_error(ArgumentError), "#{bib}: No error raised for #{bad_cd} (should be #{cd})"
            end
          end
        end

        it 'ignores a wildcard "a" check digit, but returns the correct digit' do
          aggregate_failures do
            expected_check_digits_by_bib.each do |bib, cd|
              wildcard = "#{bib}a"
              expected = "#{bib}#{cd}"
              begin
                actual = BibNumber.new(wildcard).to_s
                expect(actual).to eq(expected)
              rescue ArgumentError => e
                raise("Expected #{wildcard} not to raise error, got #{e.class}: #{e}")
              end
            end
          end
        end
      end

      describe :marc_record do
        it 'returns the MARC record' do
          raw_bib_number = 'b11082434'
          stub_sru_request(raw_bib_number)

          bib_number = BibNumber.new(raw_bib_number)
          marc_record = bib_number.get_marc_record
          expect(marc_record).not_to be_nil
          expect(marc_record.record_id).to eq('991038544199706532')
        end
      end
    end
  end
end
