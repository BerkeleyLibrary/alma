require 'berkeley_library/logging'
require 'berkeley_library/marc'
require 'berkeley_library/util/uris'
require 'berkeley_library/alma/constants'

module BerkeleyLibrary
  module Alma
    module RecordId
      include BerkeleyLibrary::Logging
      include BerkeleyLibrary::Util
      include Constants

      def marc_uri
        query_string = URI.encode_www_form(
          'version' => '1.2',
          'operation' => 'searchRetrieve',
          'query' => sru_query_value
        )

        URIs.append(config.alma_sru_base_uri, '?', query_string)
      end

      # rubocop:disable Naming/AccessorMethodName
      def get_marc_record
        marc_xml = URIs.get(marc_uri, headers: { user_agent: DEFAULT_USER_AGENT })
        logger.warn("GET #{marc_uri} did not return a MARC record") unless (marc_record = parse_marc_xml(marc_xml))
        marc_record
      rescue RestClient::Exception => e
        logger.warn("GET #{marc_uri} failed", e)
        nil
      end
      # rubocop:enable Naming/AccessorMethodName

      def config
        BerkeleyLibrary::Alma::Config
      end

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
