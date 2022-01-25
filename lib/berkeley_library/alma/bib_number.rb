require 'berkeley_library/alma/record_id'

module BerkeleyLibrary
  module Alma
    # {RecordId} subclass representing a Millennium bib number.
    class BibNumber
      include RecordId

      # ------------------------------------------------------------
      # Accessors

      # @return [String] the numeric part of the bib number, excluding check digit, as a string
      attr_reader :digit_str

      # @return [String] the check digit of the bib number, as a string
      attr_reader :check_str

      # ------------------------------------------------------------
      # Initializer

      # Initializes a new {BibNumber} from the specified string.
      #
      # @param [String] bib_number The bib number, with or without check digit
      # @raise [ArgumentError] if the specified string is not an 8- or 9-digit bib number,
      #        or if a 9-digit bib number has an incorrect check digit
      def initialize(bib_number)
        @digit_str, @check_str = split_bib(bib_number)
      end

      # ------------------------------------------------------------
      # Instance methods

      # Returns the full bib number, including the correct check digit, as a string.
      #
      # @return [String] the bib number, as a string
      def full_bib
        "b#{digit_str}#{check_str}"
      end

      # Returns the full bib number, including the correct check digit, as a string.
      #
      # @return [String] the bib number, as a string
      def to_s
        full_bib
      end

      # Returns the SRU query value for this MMS ID.
      #
      # Note that currently only UC Berkeley bib numbers (encoded `UCB-bXXXXXXXXX`)
      # are supported.
      #
      # @return [String] the SRU query value
      def sru_query_value
        # TODO: stop hard-coding `UCB-`
        other_system_number = "UCB-#{self}-#{Config.alma_institution_code.downcase}"
        "alma.other_system_number=#{other_system_number}"
      end

      # ------------------------------------------------------------
      # Private methods

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
