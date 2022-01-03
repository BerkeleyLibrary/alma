require 'spec_helper'

module BerkeleyLibrary
  module Alma
    module Lookup
      describe BibNumber do
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
      end
    end
  end
end