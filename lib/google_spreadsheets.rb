require 'google_spreadsheets/version'
require 'active_support'
require 'active_resource'
require 'time'
require 'erb'

module GoogleSpreadsheets
  extend ActiveSupport::Autoload

  autoload :Base
  autoload :Connection
  autoload :GDataFormat
  autoload :Spreadsheet
  autoload :Worksheet
  autoload :List

  autoload :Enhanced
  autoload :LinkRelations

  class BaseError < StandardError
    DefaultMessage = nil
    def initialize(message=nil)
      super(message || self.class::DefaultMessage)
    end
  end
  class NotSupportedError < StandardError
    DefaultMessage = "Google Spreadsheets Data API doesn't support this operation"
  end
  class EditLinkNotFoundError < StandardError
    DefaultMessage = "No edit link"
  end
end
