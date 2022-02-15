require 'berkeley_library/alma/record_id'

module BerkeleyLibrary
  module Alma
    # {RecordId} subclass representing an item barcode.
    class BarCode
      include RecordId

      attr_reader :barcode

      # Initialize a barcode. Since we purchase barcodes of varied formats and accept vendor
      # barcodes as well we are only validating whether it's a string or not.
      def initialize(barcode)
        string?(barcode)
        @barcode = barcode
      end

      # Returns the SRU query value for this Barcode.
      #
      # @return [String] the Barcode query value
      def sru_query_value
        "alma.barcode=#{@barcode}"
      end

      private

      def string?(barcode)
        raise ArgumentError, "Barcode must be a string: #{barcode.inspect}" unless barcode.is_a?(String)
      end

    end
  end
end
