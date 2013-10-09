# http://webos-goodies.googlecode.com/svn/trunk/blog/articles/active_resource_google_spreadsheets_data_api/ares_google_spreadsheets.rb
require 'rubygems'
require 'active_support'
require 'active_resource'
require 'time'
require 'erb'

module GoogleSpreadsheets

  class BaseError < StandardError
    DefaultMessage = nil
    def initialize(message=nil)
      super(message || self.class::DefaultMessage)
    end
  end
  class NotSupportedError < StandardError
    DefaultMessage = "Google Spreadsheets Data API doesn't support this operation"
  end
  class EditLinkNotFoundError < StandardError
    DefaultMessage = "No edit link"
  end

  class Connection < ActiveResource::Connection
    DEBUG = false
    def authorization_header
      if @user && @password && !@token
        email            = CGI.escape(@user)
        password         = CGI.escape(@password)
        http             = Net::HTTP.new('www.google.com', 443)
        http.use_ssl     = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        resp, data = http.post('/accounts/ClientLogin',
                               "accountType=HOSTED_OR_GOOGLE&Email=#{email}&Passwd=#{password}&service=wise",
                               { 'Content-Type' => 'application/x-www-form-urlencoded' })
        handle_response(resp)
        @token = (data || resp.body)[/Auth=(.*)/n, 1]
      end
      @token ? { 'Authorization' => "GoogleLogin auth=#{@token}" } : {}
    end
    def http() http = super; http.set_debug_output($stderr) if DEBUG; http end
  end

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
      returning connection.put(edit_path, encode, self.class.headers) do |response|
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

  class Spreadsheet < Base
    @connection = nil # avoid using base class's connection.
    self.prefix = '/private/full/'
    class << self; attr_accessor_with_default(:collection_name) { 'spreadsheets' } end
  end

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
    class << self; attr_accessor_with_default(:collection_name) { 'worksheets' } end
  end

  class List < Base
    class Format < GDataFormat
      def decode(xml) super(xml.gsub(/<(\/?)gsx:/u, '<\1gsx_')) end
      def encode(hash, options = {})
        super(Hash[*hash.map{|p| /^gsx_(.+)/ === p[0] ? ['gsx:'+$1, p[1]] : nil }.compact.flatten],
              { :namespaces => { 'gsx' => 'http://schemas.google.com/spreadsheets/2006/extended' } })
      end
    end
    @connection = nil # avoid using base class's connection.
    self.prefix = '/:document_id/:worksheet_id/:visibility/:projection/'
    self.format = Format.new
    class << self; attr_accessor_with_default(:collection_name) { 'list' } end
  end

end
