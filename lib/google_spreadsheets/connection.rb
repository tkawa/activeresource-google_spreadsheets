module GoogleSpreadsheets
  class Connection < ActiveResource::Connection
    DEBUG = false
    def authorization_header(http_method, uri)
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
end
