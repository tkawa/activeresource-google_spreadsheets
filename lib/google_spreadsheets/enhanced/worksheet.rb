module GoogleSpreadsheets
  module Enhanced
    class Worksheet < GoogleSpreadsheets::Worksheet
      extend GoogleSpreadsheets::LinkRelations
      include NamespacePreservable

      links_to_many :rows, rel: 'http://schemas.google.com/spreadsheets/2006#listfeed',
                           class_name: 'google_spreadsheets/enhanced/row'
      self.collection_parser = Collection
    end
  end
end
