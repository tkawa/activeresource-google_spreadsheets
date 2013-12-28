module GoogleSpreadsheets
  module Enhanced
    class Row < GoogleSpreadsheets::List
      extend GoogleSpreadsheets::LinkRelations
      include NamespacePreservable

      self.collection_parser = Collection
      self.primary_key = :'gsx:id'
    end
  end
end
