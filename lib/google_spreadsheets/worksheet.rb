module GoogleSpreadsheets
  class Worksheet < Base
    class Format < GDataFormat
      def encode(hash, options = {})
        super({'title'=>hash['title'],'gs:rowCount'=>hash['rowCount'],'gs:colCount'=>hash['colCount']},
              { :namespaces => { 'gs' => 'http://schemas.google.com/spreadsheets/2006' } })
      end
      private
      def format_entry(e)
        e = super
        e['rowCount'] = e['rowCount'].to_i if e.has_key?('rowCount')
        e['colCount'] = e['colCount'].to_i if e.has_key?('colCount')
      end
    end
    @connection = nil # avoid using base class's connection.
    self.prefix = '/:document_id/:visibility/:projection/'
    self.format = Format.new
    def self.collection_name; 'worksheets' end
  end
end
