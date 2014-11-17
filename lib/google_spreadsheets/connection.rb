module GoogleSpreadsheets
  class Connection < ActiveResource::Connection
    def authorization_header(http_method, uri)
      if auth_type == :bearer
        { 'Authorization' => "Bearer #{access_token}" }
      else
        client_login_authorization_header(http_method, uri)
      end
    end

    def access_token
      @password.is_a?(Proc) ? @password.call : @password
    end

    # Deprecated and Not recommended
    def client_login_authorization_header(http_method, uri)
      if @user && @password && !@auth_token
        email            = CGI.escape(@user)
        password         = CGI.escape(@password)
        http             = Net::HTTP.new('www.google.com', 443)
        http.use_ssl     = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        resp, data = http.post('/accounts/ClientLogin',
                               "accountType=HOSTED_OR_GOOGLE&Email=#{email}&Passwd=#{password}&service=wise",
                               { 'Content-Type' => 'application/x-www-form-urlencoded' })
        handle_response(resp)
        @auth_token = (data || resp.body)[/Auth=(.*)/n, 1]
      end
      @auth_token ? { 'Authorization' => "GoogleLogin auth=#{@auth_token}" } : {}
    end

    private
    def legitimize_auth_type(auth_type)
      auth_type = auth_type.to_sym
      auth_type.in?([:basic, :digest, :bearer]) ? auth_type : :basic
    end
  end
end
