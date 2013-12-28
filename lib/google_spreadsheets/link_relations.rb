module GoogleSpreadsheets
  module LinkRelations
    module Builder
      class HasLinkOfMany < ActiveResource::Associations::Builder::Association
        self.macro = :has_link_of_many
        self.valid_options = [:class_name, :rel]

        def build
          validate_options
          model.create_reflection(self.class.macro, name, options).tap do |reflection|
            model.defines_has_link_of_many_finder_method(reflection.name, reflection.options[:rel], reflection.klass)
          end
        end
      end
    end

    def has_link_of_many(name, options = {})
      Builder::HasLinkOfMany.build(self, name, options)
    end

    def defines_has_link_of_many_finder_method(method_name, relation_name, association_model)
      ivar_name = :"@#{method_name}"

      define_method(method_name) do
        if instance_variable_defined?(ivar_name)
          instance_variable_get(ivar_name)
        elsif attributes.include?(method_name)
          attributes[method_name]
        else
          link = self.link.find{|l| l.rel ==  relation_name }
          path = link.href.slice(%r|^https://spreadsheets\.google\.com(/.*)|, 1)
          instance_variable_set(ivar_name, association_model.find(:all, from: path))
        end
      end
    end
  end
end
