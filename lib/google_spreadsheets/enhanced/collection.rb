require 'ostruct'

module GoogleSpreadsheets
  module Enhanced
    class Collection < ActiveResource::Collection
      def find(*args)
        if block_given?
          to_a.find{|*block_args| yield(*block_args) }
        else
          to_a.find{|element| element.id.to_s == args.first.to_s }
        end
      end

      def find_by(condition_hash)
        condition_hash.inject(self.to_a) do |array, (attr, value)|
          array.find{|element| element.send(attr) == value }
        end
      end

      def find_by!(condition_hash)
        find_by(condition_hash) or raise ActiveResource::ResourceNotFound.new(OpenStruct.new(message: "Can't find #{condition_hash}"))
      end
    end
  end
end
