module GoogleSpreadsheets
  module Enhanced
    module NamespacePreservable
      module NokogiriParser
        # convert to Hash from XML including namespace
        # https://gist.github.com/baroquebobcat/1603671
        def hash_from_xml_with_namespace(xml_io)
          result = Nokogiri::XML(xml_io)
          { result.root.name => xml_node_to_hash(result.root) }
        end

        private
        def xml_node_to_hash(node)
          # If we are at the root of the document, start the hash
          if node.element?
            result_hash = {}

            node.attributes.each do |key, attr|
              result_hash[namespaced_name_from_node(attr)] = prepare(attr.value)
            end

            node.children.each do |child|
              result = xml_node_to_hash(child)
              if child.is_a? Nokogiri::XML::Text
                unless child.next_sibling || child.previous_sibling
                  return prepare(result)
                end
              elsif result_hash[child_name = namespaced_name_from_node(child)]
                result_hash[child_name] = [result_hash[child_name]] unless result_hash[child_name].is_a?(::Array)
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

        def namespaced_name_from_node(node)
          (node.namespace.try(:prefix).present? ? "#{node.namespace.prefix}:" : '') + node.name
        end
      end
    end
  end
end
