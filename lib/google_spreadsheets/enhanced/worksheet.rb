module GoogleSpreadsheets
  module Enhanced
    class Worksheet < GoogleSpreadsheets::Worksheet
      extend GoogleSpreadsheets::LinkRelations
      include NamespacePreservable

      has_link_of_many :rows, rel: 'http://schemas.google.com/spreadsheets/2006#listfeed',
                              class_name: 'google_spreadsheets/enhanced/row'
      self.collection_parser = Collection
    end
  end
end
