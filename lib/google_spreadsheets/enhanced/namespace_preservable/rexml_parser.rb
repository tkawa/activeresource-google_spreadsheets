require 'rexml/document'

module GoogleSpreadsheets
  module Enhanced
    module NamespacePreservable
      module RexmlParser
        def hash_from_xml_with_namespace(xml_io)
          rexml = REXML::Document.new(xml_io)
          { rexml.root.name => xml_node_to_hash(rexml.root) }
        end

        private
        def xml_node_to_hash(node)
          if node.node_type == :element
            result_hash = {}

            node.attributes.each do |name, attr|
              result_hash[name] = prepare(attr)
            end

            node.each_child do |child|
              result = xml_node_to_hash(child)
              if child.node_type == :text
                unless child.next_sibling_node || child.previous_sibling_node
                  return prepare(result)
                end
              elsif result_hash[child_name = child.expanded_name]
                result_hash[child_name] = [result_hash[child_name]] unless result_hash[child_name].is_a?(Array)
                result_hash[child_name] << prepare(result)
              else
                result_hash[child_name] = prepare(result)
              end
            end
            result_hash
          else
            prepare(node.value)
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
    end
  end
end
