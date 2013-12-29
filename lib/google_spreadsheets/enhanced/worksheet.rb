module GoogleSpreadsheets
  module Enhanced
    class Worksheet < GoogleSpreadsheets::Worksheet
      include GoogleSpreadsheets::LinkRelations
      include NamespacePreservable

      links_to_many :rows, rel: 'http://schemas.google.com/spreadsheets/2006#listfeed'
      self.collection_parser = Collection
    end
  end
end
