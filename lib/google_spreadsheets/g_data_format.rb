module GoogleSpreadsheets
  class GDataFormat
    def extension() '' end
    def mime_type() 'application/atom+xml' end
    def decode(xml)
      e = Hash.from_xml(xml)
      if e.has_key?('feed')
        e = e['feed']['entry'] || []
        (e.is_a?(Array) ? e : [e]).each{|i| format_entry(i) }
      else
        format_entry(e['entry'])
      end
    end
    def encode(hash, options = {})
      root = REXML::Element.new('entry')
      root.add_namespace('http://www.w3.org/2005/Atom')
      (options[:namespaces] || {}).each{|key, value| root.add_namespace(key, value) }
      hash.each do |key, value|
        next unless value
        e = REXML::Element.new(key, root)
        e.text = value
      end
      root.to_s
    end
    private
    def format_entry(e)
      e['id']      = e['id'][/[^\/]+\z/u] if e.has_key?('id')
      e['updated'] = (Time.xmlschema(e['updated']) rescue Time.parse(e['updated'])) if e.has_key?('updated')
      e
    end
  end
end
