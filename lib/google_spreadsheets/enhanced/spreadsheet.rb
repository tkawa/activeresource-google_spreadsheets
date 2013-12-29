module GoogleSpreadsheets
  module Enhanced
    class Spreadsheet < GoogleSpreadsheets::Spreadsheet
      include GoogleSpreadsheets::LinkRelations
      include NamespacePreservable

      links_to_many :worksheets, rel: 'http://schemas.google.com/spreadsheets/2006#worksheetsfeed'
      self.collection_parser = Collection
    end
  end
end
