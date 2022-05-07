require 'uri'
require 'berkeley_library/util/uris'
require 'berkeley_library/alma/config'
require 'berkeley_library/alma/constants'
require 'berkeley_library/alma/record_id'
require 'berkeley_library/alma/sru/xml_reader'

module BerkeleyLibrary
  module Alma
    module SRU
      include BerkeleyLibrary::Logging
      include Constants

      DEFAULT_MAX_RECORDS = 10

      class << self
        include SRU
      end

      # Given a list of record IDs, returns the MARC records for each ID (if found).
      # Note that the order of the records is not guaranteed.
      #
      # @param record_ids [Array<String, RecordId>] the record IDs to look up
      # @param freeze [Boolean] whether to freeze the records
      # @param max_records the number of records per SRU page.
      # @return [Enumerator::Lazy<MARC::Record>] the records
      def get_marc_records(*record_ids, max_records: DEFAULT_MAX_RECORDS, freeze: false)
        # noinspection RubyMismatchedReturnType
        parsed_ids = record_ids.filter_map { |id| RecordId.parse(id) }
        raise ArgumentError, "Argument #{record_ids.inspect} contain no valid record IDs" if parsed_ids.empty?

        sru_query_value = parsed_ids.map(&:sru_query_value).join(' or ')
        SRU.marc_records_for(sru_query_value, max_records: max_records, freeze: freeze)
      end

      # Returns a URI for retrieving records for the specified query
      # via SRU. Requires {Config#alma_sru_base_uri} to be set.
      #
      # @return [URI] the MARC URI
      # @param max_records the number of records per SRU page
      def sru_query_uri(sru_query_value, max_records: DEFAULT_MAX_RECORDS)
        query_string = URI.encode_www_form(
          'version' => '1.2',
          'operation' => 'searchRetrieve',
          'query' => sru_query_value
        )

        Util::URIs.append(Config.alma_sru_base_uri, '?', query_string, '&', "maximumRecords=#{max_records}")
      end

      # Makes an SRU query for the specified query value and returns the query response
      # as a string.
      #
      # @param query_value [String] the value of the SRU query parameter
      # @param max_records the number of records per SRU page
      # @return [String, nil] the SRU query response body, or nil in the event of an error.
      def make_sru_query(query_value, max_records: DEFAULT_MAX_RECORDS)
        uri = sru_query_uri(query_value, max_records: max_records)
        do_get(uri)
      end

      # Makes an SRU query for the specified query value and returns the query response
      # as MARC records.
      #
      # @param query_value [String] the value of the SRU query parameter
      # @param freeze [Boolean] whether to freeze the records
      # @param max_records the number of records per SRU page
      # @return [Enumerator::Lazy<MARC::Record>] the records
      def marc_records_for(query_value, max_records: DEFAULT_MAX_RECORDS, freeze: false)
        Enumerator.new do |y|
          uri = sru_query_uri(query_value, max_records: max_records)
          perform_query(uri, freeze: freeze) { |rec| y << rec }
        end.lazy
      end

      private

      def perform_query(query_uri, start_record: nil, freeze: false, &block)
        full_query_uri = full_query_uri_for(query_uri, start_record)
        next_start_record = perform_single_query(full_query_uri, freeze, &block)
        return unless next_start_record

        perform_query(query_uri, start_record: next_start_record, freeze: freeze, &block)
      end

      def full_query_uri_for(query_uri, start_record)
        return query_uri unless start_record

        BerkeleyLibrary::Util::URIs.append(query_uri, "&startRecord=#{start_record}")
      end

      def perform_single_query(query_uri, freeze, &block)
        return unless (xml = do_get(query_uri))

        xml_reader = XMLReader.read(xml, freeze: freeze)
        xml_reader.each(&block)
        xml_reader.next_record_position
      end

      def do_get(uri)
        Util::URIs.get(uri, headers: { user_agent: DEFAULT_USER_AGENT })
      rescue RestClient::Exception => e
        logger.warn("GET #{uri} failed", e)
        nil
      end
    end
  end
end
