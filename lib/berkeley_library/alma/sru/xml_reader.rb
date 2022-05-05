require 'nokogiri'
require 'marc/xml_parsers'
require 'berkeley_library/util/files'

module BerkeleyLibrary
  module Alma
    module SRU
      # A customized XML reader for reading MARC records from SRU search results.
      class XMLReader
        include Enumerable
        include ::MARC::NokogiriReader
        include BerkeleyLibrary::Util::Files

        # ############################################################
        # Constants

        NS_SRW = 'http://www.loc.gov/zing/srw/'.freeze
        NS_MARC = 'http://www.loc.gov/MARC21/slim'.freeze

        # ############################################################
        # Attributes

        # @return [Integer, nil] the record identifier of the most recently parsed record, if any
        attr_reader :last_record_id

        # @return [Integer, nil] the record position of the most recently parsed record, if any
        attr_reader :last_record_position

        # @return [Integer, nil] the next record position, if present
        attr_reader :next_record_position

        # Returns the total number of records, based on the `<numberOfRecords/>` tag
        # returned in the SRU response.
        #
        # Note that the total is not guaranteed to be present, and if present,
        # may not be present unless at least some records have been parsed.
        #
        # @return [Integer, nil] the total number of records, or `nil` if the total has not been read yet
        def num_records
          @num_records&.to_i
        end

        # Returns the number of records yielded.
        #
        # @return [Integer] the number of records yielded.
        def records_yielded
          @records_yielded ||= 0
        end

        # ############################################################
        # Initializer

        def initialize(source, freeze: false)
          @handle = ensure_io(source)
          @freeze = freeze
          init
        end

        class << self
          # Reads MARC records from an XML datasource given either as an XML string, a file path,
          # or as an IO object.
          #
          # @param source [String, Pathname, IO] an XML string, the path to a file, or an IO to read from directly
          # @param freeze [Boolean] whether to freeze each record after reading
          def read(source, freeze: false)
            new(source, freeze: freeze)
          end
        end

        # ############################################################
        # MARC::GenericPullParser overrides

        def yield_record
          @record[:record].tap do |record|
            record.freeze if @freeze
          end

          super
        ensure
          increment_records_yielded!
        end

        # ############################################################
        # Nokogiri::XML::SAX::Document overrides

        # @see Nokogiri::XML::Sax::Document#start_element_namespace
        # rubocop:disable Metrics/ParameterLists
        def start_element_namespace(name, attrs = [], prefix = nil, uri = nil, ns = [])
          super

          @current_element_ns = uri
          @current_element_name = name
        end
        # rubocop:enable Metrics/ParameterLists

        # @see Nokogiri::XML::Sax::Document#end_element_namespace
        def end_element_namespace(name, prefix = nil, uri = nil)
          # Delay yielding record till we reach the end of the outer SRU <record/>
          # element (not the inner MARC <record/> element), so we can record the
          # values of <recordIdentifier> and <recordPosition/>
          if name.downcase == 'record'
            yield_record if uri == NS_SRW
          elsif uri == NS_MARC
            super
          end

          @current_element_name = nil
        end

        # @see Nokogiri::XML::Sax::Document#characters
        # rubocop:disable Metrics/MethodLength
        def characters(string)
          return super unless NS_SRW == @current_element_ns
          return unless (name = @current_element_name)

          case name
          when 'numberOfRecords'
            @num_records = string
          when 'recordIdentifier'
            @last_record_id = string
          when 'recordPosition'
            @last_record_position = string.to_i
          when 'nextRecordPosition'
            @next_record_position = string.to_i
          end
        end
        # rubocop:enable Metrics/MethodLength

        # ############################################################
        # Private

        private

        def ensure_io(file)
          return file if reader_like?(file)
          return File.new(file) if file_exists?(file)
          return StringIO.new(file) if file =~ /^\s*</x

          raise ArgumentError, "Don't know how to read XML from #{file.inspect}: not an IO, file path, or XML text"
        end

        def increment_records_yielded!
          @records_yielded = records_yielded + 1
        end
      end
    end
  end
end
