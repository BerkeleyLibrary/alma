require 'berkeley_library/alma/record_id'

module BerkeleyLibrary
  module Alma
    class BibNumber
      include RecordId

      attr_reader :digit_str
      attr_reader :check_str

      def initialize(bib_number)
        @digit_str, @check_str = split_bib(bib_number)
      end

      def to_s
        "b#{digit_str}#{check_str}"
      end

      def sru_query_value
        other_system_number = "UCB-#{self}-#{config.alma_institution_code.downcase}"
        "alma.other_system_number=#{other_system_number}"
      end

      private

      def split_bib(bib_number)
        raise ArgumentError, "Not a Millennium bib number: #{bib_number.inspect}" unless (md = MILLENNIUM_RECORD_RE.match(bib_number.to_s))

        digit_str, check_str_orig = %i[digits check].map { |part| md[part] }
        check_str = ensure_check_digit(digit_str, check_str_orig)

        [digit_str, check_str]
      end

      def ensure_check_digit(digit_str, check_str_orig)
        digits = digit_str.chars.map(&:to_i)
        check_digit = calculate_check_digit(digits)
        return check_digit if [nil, check_digit, 'a'].include?(check_str_orig)

        raise ArgumentError, "#{digit_str}#{check_str_orig} check digit invalid: expected #{check_digit}, got #{check_str_orig}"
      end

      def calculate_check_digit(digits)
        raise ArgumentError, "Not an 8-digit array : #{digits.inspect}" unless digits.is_a?(Array) && digits.size == 8

        # From: http://liwong.blogspot.com/2018/04/recipe-computing-millennium-checkdigit.html
        mod = digits.reverse.each_with_index.inject(0) { |sum, (v, i)| sum + (v * (i + 2)) } % 11
        mod == 10 ? 'x' : mod.to_s
      end
    end
  end
end
