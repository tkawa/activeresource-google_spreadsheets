module GoogleSpreadsheets
  class Base < ActiveResource::Base
    self.site   = 'http://spreadsheets.google.com/'
    self.format = GDataFormat.new

    class << self
      def connection(refresh = false)
        if defined?(@connection) || self == Base
          @connection = Connection.new(site, format) if refresh || @connection.nil?
          @connection.user = user if user
          @connection.password = password if password
          @connection.timeout = timeout if timeout
          @connection
        else
          superclass.connection
        end
      end
      def element_path(id, prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "/feeds/#{collection_name}#{prefix(prefix_options)}#{id}#{query_string(query_options)}"
      end
      def collection_path(prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "/feeds/#{collection_name}#{prefix(prefix_options)}#{query_string(query_options)}"
      end
      def custom_method_collection_url(method_name, options = {}) raise NotSupportedError.new end
      def delete(id, options = {})  raise NotSupportedError.new end
      def exists?(id, options = {}) raise NotSupportedError.new end
    end

    def custom_method_element_url(method_name, options = {})     raise NotSupportedError.new end
    def custom_method_new_element_url(method_name, options = {}) raise NotSupportedError.new end

    def destroy() connection.delete(edit_path, self.class.headers) end

    protected

    def update
      connection.put(edit_path, encode, self.class.headers).tap do |response|
        load_attributes_from_response(response)
      end
    end
    def edit_path()
      s = self.class.site
      (self.attributes['link'] || []).map{|l| l.rel == 'edit' ? l.href : nil }.compact.each do |href|
        e = URI.parse(href)
        return e.request_uri if s.scheme == e.scheme && s.port == e.port && s.host == e.host
      end
      raise EditLinkNotFoundError.new
    end
  end
end
