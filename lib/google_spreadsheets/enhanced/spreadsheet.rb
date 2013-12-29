module GoogleSpreadsheets
  module Enhanced
    class Spreadsheet < GoogleSpreadsheets::Spreadsheet
      extend GoogleSpreadsheets::LinkRelations
      include NamespacePreservable

      links_to_many :worksheets, rel: 'http://schemas.google.com/spreadsheets/2006#worksheetsfeed',
                                 class_name: 'google_spreadsheets/enhanced/worksheet'
      self.collection_parser = Collection
    end
  end
end
