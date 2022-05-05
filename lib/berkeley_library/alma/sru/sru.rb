require 'uri'
require 'berkeley_library/alma/config'
require 'berkeley_library/alma/constants'
require 'berkeley_library/alma/record_id'
require 'berkeley_library/util/uris'

module BerkeleyLibrary
  module Alma
    module SRU
      include BerkeleyLibrary::Logging
      include Constants

      class << self
        include SRU
      end

      # Given a list of record IDs, returns the MARC records for each ID (if found).
      #
      # @param record_ids [Array<String, RecordId>] the record IDs to look up
      # @return [MARC::XMLReader, nil] a reader for the MARC records, or nil if
      #   the records could not be read
      def get_marc_records(*record_ids)
        # noinspection RubyMismatchedReturnType
        parsed_ids = record_ids.filter_map { |id| RecordId.parse(id) }
        raise ArgumentError, "Argument #{record_ids.inspect} contain no valid record IDs" if parsed_ids.empty?

        sru_query_value = parsed_ids.map(&:sru_query_value).join(' or ')
        SRU.marc_records_for(sru_query_value)
      end

      # Returns a URI for retrieving records for the specified query
      # via SRU. Requires {Config#alma_sru_base_uri} to be set.
      #
      # @return [URI] the MARC URI
      def sru_query_uri(sru_query_value)
        query_string = URI.encode_www_form(
          'version' => '1.2',
          'operation' => 'searchRetrieve',
          'query' => sru_query_value
        )

        Util::URIs.append(Config.alma_sru_base_uri, '?', query_string)
      end

      # Makes an SRU query for the specified query value and returns the query response
      # as a string.
      #
      # @param query_value [String] the value of the SRU query parameter
      # @return [String, nil] the SRU query response body, or nil in the event of an error.
      def make_sru_query(query_value)
        uri = sru_query_uri(query_value)
        do_get(uri)
      end

      # Makes an SRU query for the specified query value and returns the query response
      # as MARC records.
      #
      # @param query_value [String] the value of the SRU query parameter
      # @return [MARC::XMLReader, nil] a reader for the MARC records, or nil if
      #   the records could not be read
      def marc_records_for(query_value)
        return unless (xml = make_sru_query(query_value))

        input = StringIO.new(xml.scrub)
        MARC::XMLReader.new(input, parser: 'nokogiri')
      end

      private

      def do_get(uri)
        # TODO: can we get the XML as an IO rather than as a string?
        Util::URIs.get(uri, headers: { user_agent: DEFAULT_USER_AGENT })
      rescue RestClient::Exception => e
        logger.warn("GET #{uri} failed", e)
        nil
      end
    end
  end
end
