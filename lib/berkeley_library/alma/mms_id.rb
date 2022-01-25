require 'berkeley_library/util/uris'
require 'berkeley_library/alma/record_id'

module BerkeleyLibrary
  module Alma
    # {RecordId} subclass representing an Alma MMS ID. Note that only
    # bibliographic records (prefix `99`) are supported.
    #
    # See [Record Numbers](https://knowledge.exlibrisgroup.com/Alma/Product_Documentation/010Alma_Online_Help_(English)/Metadata_Management/005Introduction_to_Metadata_Management/020Record_Numbers)
    # in the Alma documentation.
    class MMSID
      include BerkeleyLibrary::Util
      include RecordId

      # ------------------------------------------------------------
      # Constants

      # The UC Berkeley prefix to the unique part of the MMS ID
      UNIQ_PREFIX_UCB = '10'.freeze

      # The four-digit institition code for UC berkeley
      INST_CODE_UCB = '6532'.freeze

      # ------------------------------------------------------------
      # Accessors

      # @return [String] the MMS ID, as a string
      attr_reader :mms_id

      # @return [String] the type prefix part of the MMS ID. Note that only bibliographic records
      #         (prefix `99`) are supported.
      attr_reader :type_prefix

      # @return [String] the unique part of the record number
      attr_reader :unique_part

      # @return [String] the four-digit institution code
      attr_reader :institution

      # ------------------------------------------------------------
      # Initializer

      # Initializes a new {MMSID} from a string.
      #
      # @param id [String] the ID string
      # @raise [ArgumentError] if the specified string is not an Alma bibliographic MMS ID.
      def initialize(id)
        @mms_id, @type_prefix, @unique_part, @institution = parse_mms_id(id)
      end

      # ------------------------------------------------------------
      # Instance methods

      # Returns the MMS ID as a string.
      #
      # @return [String] the MMS ID
      def to_s
        mms_id
      end

      # Returns the permalink URI for this MMS ID.
      # Requires {Config#alma_permalink_base_uri} to be set.
      #
      # @return [URI] the permalink URI.
      def permalink_uri
        URIs.append(permalink_base_uri, "alma#{mms_id}")
      end

      # Returns the SRU query value for this MMS ID.
      #
      # @return [String] the SRU query value
      def sru_query_value
        "alma.mms_id=#{mms_id}"
      end

      # Whether this ID appears to be for a Berkeley record, based on its institution code and on
      # whether the unique part of the ID starts with the expected prefix for Berkeley.
      #
      # @return [TrueClass, FalseClass] true if this ID appears to be for a Berkeley record, false otherwise
      def berkeley?
        unique_part.start_with?(UNIQ_PREFIX_UCB) && institution == INST_CODE_UCB
      end

      # ------------------------------------------------------------
      # Private methods

      private

      def permalink_base_uri
        Config.alma_permalink_base_uri
      end

      def parse_mms_id(id)
        raise ArgumentError, "Not an MMS ID: #{id.inspect}" unless (md = ALMA_RECORD_RE.match(id.to_s))

        md.to_a
      end
    end
  end
end
