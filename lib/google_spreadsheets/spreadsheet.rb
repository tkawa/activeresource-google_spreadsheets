module GoogleSpreadsheets
  class Spreadsheet < Base
    self._connection = nil # avoid using base class's connection.
    self.prefix = '/private/full/'
    def self.collection_name; 'spreadsheets' end
  end
end
