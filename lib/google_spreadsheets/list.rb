module GoogleSpreadsheets
  class List < Base
    class Format < GDataFormat
      def decode(xml)
        xml.force_encoding('UTF-8') # cf. http://d.hatena.ne.jp/kitamomonga/20101218/ruby_19_net_http_encoding
        super(xml.gsub(/<(\/?)gsx:/u, '<\1gsx_'))
      end
      def encode(hash, options = {})
        super(Hash[*hash.map{|p| /^gsx_(.+)/ === p[0] ? ['gsx:'+$1, p[1]] : nil }.compact.flatten],
              { :namespaces => { 'gsx' => 'http://schemas.google.com/spreadsheets/2006/extended' } })
      end
    end
    self._connection = nil # avoid using base class's connection.
    self.prefix = '/:document_id/:worksheet_id/:visibility/:projection/'
    self.format = Format.new
    def self.collection_name; 'list' end
  end
end
