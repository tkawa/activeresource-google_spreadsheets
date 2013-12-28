module GoogleSpreadsheets
  module Enhanced
    class Collection < ActiveResource::Collection
      def find_by(condition_hash)
        condition_hash.inject(self) do |rel, (attr, value)|
          rel.find{|element| element.send(attr) == value }
        end
      end
    end
  end
end
