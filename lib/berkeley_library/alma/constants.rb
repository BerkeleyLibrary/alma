require 'berkeley_library/alma/module_info'

module BerkeleyLibrary
  module Alma
    module Constants
      # 'x' represents a calculated check digit of 10; 'a' is a wildcard
      MILLENNIUM_RECORD_RE = /^[Bb](?<digits>[0-9]{8})(?<check>[0-9ax])?$/.freeze

      # '99' is the Alma prefix for a Metadata Management System ID
      # see https://knowledge.exlibrisgroup.com/Alma/Product_Documentation/010Alma_Online_Help_(English)/Metadata_Management/005Introduction_to_Metadata_Management/020Record_Numbers
      ALMA_RECORD_RE = /^(?<type>99)(?<unique_part>[0-9]{9,12})(?<institution>[0-9]{4})$/.freeze

      DEFAULT_USER_AGENT = "#{ModuleInfo::NAME} #{ModuleInfo::VERSION} (#{ModuleInfo::HOMEPAGE})".freeze
    end
  end
end
