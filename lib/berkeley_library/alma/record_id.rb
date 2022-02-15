require 'berkeley_library/logging'
require 'berkeley_library/marc'
require 'berkeley_library/util/uris'
require 'berkeley_library/alma/constants'

module BerkeleyLibrary
  module Alma
    # Encapsulates an ID that can be used to look up records in Alma via SRU.
    module RecordId
      include BerkeleyLibrary::Logging
      include BerkeleyLibrary::Util
      include Comparable
      include Constants

      # ------------------------------------------------------------
      # Class methods

      class << self
        include Constants

        # Parses a string record ID and returns a {RecordId} object. For convenience,
        # also accepts a {RecordId} and simply returns it, so it can be used in
        # situations where it may not be clear whether the ID has already been parsed.
        #
        # **Note:** Use the {BarCode} class for barcodes, which don't have a consistent
        # format and hence can't be auto-detected.
        #
        # @param id [String, RecordId] the ID to parse
        # @return [RecordId, nil] an {MMSID} or {BibNumber}, depending on the type of ID,
        #         or `nil` if the specified `id` is neither an MMS ID nor a bib number
        # @raise [ArgumentError] if the specified string is a correctly formatted Millennium
        #        bib number, but has an incorrect check digit
        def parse(id)
          # noinspection RubyMismatchedReturnType
          return id if id.is_a?(RecordId)

          return MMSID.new(id) if ALMA_RECORD_RE =~ id
          return BibNumber.new(id) if MILLENNIUM_RECORD_RE =~ id
        end
      end

      # ------------------------------------------------------------
      # Instance methods

      # Returns a URI for retrieving MARCXML from this record via SRU.
      # Requires {Config#alma_sru_base_uri} to be set.
      #
      # @return [URI] the MARC URI
      def marc_uri
        query_string = URI.encode_www_form(
          'version' => '1.2',
          'operation' => 'searchRetrieve',
          'query' => sru_query_value
        )

        URIs.append(Config.alma_sru_base_uri, '?', query_string)
      end

      # Makes an SRU query for this record and returns a MARC record, or nil if the
      # record is not found.
      #
      # Note that in the event the SRU query finds multiple records, only the first
      # record is returned.
      #
      # @return [MARC::Record, nil] the MARC record
      # rubocop:disable Naming/AccessorMethodName
      def get_marc_record
        marc_xml = get_marc_xml
        logger.warn("GET #{marc_uri} did not return a MARC record") unless (marc_record = parse_marc_xml(marc_xml))
        marc_record
      end
      # rubocop:enable Naming/AccessorMethodName

      # Makes an SRU query for this record and returns the XML query response
      # as a string.
      #
      # @return [String, nil] the SRU query response body, or nil in the event of an error.
      # rubocop:disable Naming/AccessorMethodName
      def get_marc_xml
        URIs.get(marc_uri, headers: { user_agent: DEFAULT_USER_AGENT })
      rescue RestClient::Exception => e
        logger.warn("GET #{marc_uri} failed", e)
        nil
      end
      # rubocop:enable Naming/AccessorMethodName

      # ------------------------------------------------------------
      # Comparable

      # Compares this {RecordId} with another based on their string representations.
      #
      # @see Comparable#<=>
      # @return [Integer, nil]
      def <=>(other)
        return 0 if equal?(other)
        return unless other
        return unless other.is_a?(RecordId)

        to_s <=> other.to_s
      end

      # ------------------------------------------------------------
      # Private methods

      private

      def parse_marc_xml(xml)
        return unless xml

        input = StringIO.new(xml.scrub)
        reader = MARC::XMLReader.new(input)
        reader.first
      end
    end
  end
end
