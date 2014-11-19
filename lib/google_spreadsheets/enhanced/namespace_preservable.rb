module GoogleSpreadsheets
  module Enhanced
    module NamespacePreservable
      extend ActiveSupport::Concern

      class Format < GoogleSpreadsheets::GDataFormat
        def decode(xml)
          xml.force_encoding('UTF-8') # cf. http://d.hatena.ne.jp/kitamomonga/20101218/ruby_19_net_http_encoding
          e = hash_from_xml_with_namespace(xml)
          if e.has_key?('feed')
            e = e['feed']['entry'] || []
            (e.is_a?(Array) ? e : [e]).each{|i| format_entry(i) }
          else
            format_entry(e['entry'])
          end
        end

        def encode(hash, options = {})
          super(hash.select{|key, _| key.match(/^gsx:(.+)/) },
                { :namespaces => { 'gsx' => 'http://schemas.google.com/spreadsheets/2006/extended' } })
        end

        begin
          require 'nokogiri'
          require 'google_spreadsheets/enhanced/namespace_preservable/nokogiri_parser'
          include NokogiriParser
        rescue LoadError => e
          $stderr.puts "You don't have nokogiri installed in your application, so this runs with rexml. If you want to use nokogiri, please add it to your Gemfile and run bundle install"
          require 'google_spreadsheets/enhanced/namespace_preservable/rexml_parser'
          include RexmlParser
        end
      end

      included do
        class_attribute :_attr_aliases
        self._attr_aliases = {}
        class_attribute :_ignore_attributes
        self._ignore_attributes = []
        self.format = Format.new
      end

      module ClassMethods
        def attr_aliases(aliases)
          self._attr_aliases = self._attr_aliases.merge(aliases) # not share parent class attrs
          aliases.each do |new_attr, original_attr|
            define_method(new_attr) {|*args| send(original_attr, *args) }
            define_method("#{new_attr}=") {|*args| send("#{original_attr}=", *args) }
          end
        end

        def ignore_column(*column_names)
          self._ignore_attributes += column_names.map(&:to_s)
        end
      end

      def aliased_attributes
        aliased = _attr_aliases.invert
        gsx_attributes = self.attributes.keys.map do |attr|
          if matches = attr.match(/^(gsx:)/)
            (aliased[matches.post_match] || matches.post_match).to_s
          else
            nil
          end
        end.compact
        (self.class.known_attributes + gsx_attributes - self.class._ignore_attributes).uniq
      end

      def all_values_empty?
        self.attributes.select{|k, v| k.to_s.start_with?('gsx:') && k.to_s != 'gsx:id' }.values.all?{|v| v == '' }
      end

      def respond_to?(method, include_priv = false)
        method_name = method.to_s
        ((matches = method_name.match(/(=|\?)$/)) && attributes.include?("gsx:#{matches.pre_match}")) ||
        attributes.include?("gsx:#{method_name}") ||
        super
      end

      def method_missing(method_symbol, *arguments)
        method_name = method_symbol.to_s

        if (matches = method_name.match(/(=)$/)) && attributes.include?("gsx:#{matches.pre_match}")
          attributes["gsx:#{matches.pre_match}"] = arguments.first
        elsif (matches = method_name.match(/(\?)$/)) && attributes.include?("gsx:#{matches.pre_match}")
          attributes["gsx:#{matches.pre_match}"]
        elsif attributes.include?("gsx:#{method_name}")
          attributes["gsx:#{method_name}"]
        else
          super
        end
      end
    end
  end
end
