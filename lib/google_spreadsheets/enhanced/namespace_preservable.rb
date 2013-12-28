require 'nokogiri'

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

        private

        # convert to Hash from XML including namespace
        # https://gist.github.com/baroquebobcat/1603671
        def hash_from_xml_with_namespace(xml_io)
          begin
            result = Nokogiri::XML(xml_io)
            { result.root.name => xml_node_to_hash(result.root) }
          rescue Exception => e
            # raise your custom exception here
            raise
          end
        end

        def xml_node_to_hash(node)
          # If we are at the root of the document, start the hash
          if node.element?
            result_hash = {}

            node.attributes.each do |key, attr|
              result_hash[attr.namespaced_name] = prepare(attr.value)
            end

            node.children.each do |child|
              result = xml_node_to_hash(child)
              if child.is_a? Nokogiri::XML::Text
                unless child.next_sibling || child.previous_sibling
                  return prepare(result)
                end
              elsif result_hash[child_name = child.namespaced_name]
                result_hash[child_name] = [result_hash[child_name]] unless result_hash[child_name].is_a?(Object::Array)
                result_hash[child_name] << prepare(result)
              else
                result_hash[child_name] = prepare(result)
              end
            end

            result_hash
          else
            prepare(node.content.to_s)
          end
        end

        def prepare(data)
          if data.is_a?(String) && data.to_i.to_s == data
            data.to_i
          elsif data == {}
            ''
          else
            data
          end
        end
      end

      included do
        self.format = Format.new
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

class Nokogiri::XML::Node
  def namespaced_name
    (namespace.try(:prefix).present? ? "#{namespace.prefix}:" : '') + name
  end
end
