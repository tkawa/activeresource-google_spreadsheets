module GoogleSpreadsheets
  class Base < ActiveResource::Base
    self.site   = 'https://spreadsheets.google.com/'
    self.format = GDataFormat.new

    class << self
      # Avoid dup & freeze because of possible replacing with OAuth access token
      def password
        if _password_defined?
          _password
        elsif superclass != Object && superclass.password
          superclass.password
        end
      end

      # Inherit from superclass
      def auth_type
        if defined?(@auth_type)
          @auth_type
        elsif superclass != Object && superclass.auth_type
          superclass.auth_type
        end
      end

      def access_token=(access_token)
        self.password = access_token
      end

      def access_token(&block)
        if block_given?
          self.password = block
        else
          password
        end
      end

      # Use GoogleSpreadsheets::Connection instead of ActiveResource::Connection
      def connection(refresh = false)
        if _connection_defined? || self == GoogleSpreadsheets::Base
          self._connection = GoogleSpreadsheets::Connection.new(site, format) if refresh || _connection.nil?
          _connection.proxy = proxy if proxy
          _connection.user = user if user
          _connection.password = password if password
          _connection.auth_type = auth_type if auth_type
          _connection.timeout = timeout if timeout
          _connection.open_timeout = open_timeout if open_timeout
          _connection.read_timeout = read_timeout if read_timeout
          _connection.ssl_options = ssl_options if ssl_options
          _connection
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

    # Fix for degradation
    # cf. https://github.com/rails/activeresource/pull/94
    def encode(options={})
      self.class.format.encode(attributes, {:root => self.class.element_name}.merge(options))
    end

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
