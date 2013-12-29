module GoogleSpreadsheets
  module LinkRelations
    extend ActiveSupport::Concern

    class << self
      DEFAULT_CLASS_NAME_MAPPINGS = {
        'http://schemas.google.com/spreadsheets/2006#worksheetsfeed' => 'GoogleSpreadsheets::Enhanced::Worksheet',
        'http://schemas.google.com/spreadsheets/2006#listfeed'       => 'GoogleSpreadsheets::Enhanced::Row'
      }
      def class_name_mappings
        @class_name_mappings ||= DEFAULT_CLASS_NAME_MAPPINGS
      end
      attr_writer :class_name_mappings
    end

    module Builder
      class LinksToMany < ActiveResource::Associations::Builder::Association
        self.macro = :links_to_many
        self.valid_options = [:class_name, :rel]

        def build
          validate_options
          model.create_reflection(self.class.macro, name, options).tap do |reflection|
            model.defines_links_to_many_finder_method(reflection.name, reflection.options[:rel], reflection.klass)
          end
        end
      end
    end

    module ClassMethods
      def links_to_many(name, options = {})
        Builder::LinksToMany.build(self, name, options)
      end

      def defines_links_to_many_finder_method(method_name, relation_name, association_model)
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

      def create_reflection(macro, name, options)
        # TODO: improve
        if macro == :links_to_many
          reflection = LinkRelationReflection.new(macro, name, options)
          self.reflections = self.reflections.merge(name => reflection)
          reflection
        else
          super
        end
      end
    end

    class LinkRelationReflection < ActiveResource::Reflection::AssociationReflection
      private
      def derive_class_name
        GoogleSpreadsheets::LinkRelations.class_name_mappings[options[:rel]] ||
          (options[:class_name] ? options[:class_name].to_s : name.to_s).classify
      end
    end
  end
end
