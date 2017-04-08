require 'ostruct'

module GoogleSpreadsheets
  module Enhanced
    class Collection < ActiveResource::Collection
      def find(id)
        if block_given?
          to_a.find{|*block_args| yield(*block_args) }
        else
          find_by!(id: id)
        end
      end

      def find_by(condition_hash)
        to_a.find do |element|
          # TODO: compare with consideration of type cast
          condition_hash.all?{|attr, value| element.send(attr) == value }
        end
      end

      def find_by!(condition_hash)
        find_by(condition_hash) ||
          raise(ActiveResource::ResourceNotFound.new(OpenStruct.new(message: "Couldn't find #{self.class.name} with #{condition_hash}")))
      end

      def where(condition_hash)
        conditioned_elements = condition_hash.inject(self.to_a) do |array, (attr, value)|
          array.find_all{|element| element.send(attr) == value }
        end
        self.class.new(conditioned_elements).tap do |collection|
          collection.resource_class  = self.resource_class
          collection.original_params = self.original_params
        end
      end
    end
  end
end
