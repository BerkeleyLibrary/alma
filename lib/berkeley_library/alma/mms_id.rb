require 'berkeley_library/util/uris'
require 'berkeley_library/alma/record_id'

module BerkeleyLibrary
  module Alma
    class MMSID
      include BerkeleyLibrary::Util
      include RecordId

      INST_CODE_UCB = '6532'.freeze

      attr_reader :mms_id, :type_prefix, :unique_part, :institution

      def initialize(id)
        @mms_id, @type_prefix, @unique_part, @institution = parse_mms_id(id)
      end

      def to_s
        mms_id
      end

      def permalink_uri
        URIs.append(permalink_base_uri, "alma#{mms_id}")
      end

      def sru_query_value
        "alma.mms_id=#{mms_id}"
      end

      def berkeley?
        unique_part.start_with?('10') && institution == INST_CODE_UCB
      end

      private

      def permalink_base_uri
        config.alma_permalink_base_uri
      end

      def parse_mms_id(id)
        raise ArgumentError, "Not an MMS ID: #{id.inspect}" unless (md = ALMA_RECORD_RE.match(id.to_s))

        md.to_a
      end
    end
  end
end
