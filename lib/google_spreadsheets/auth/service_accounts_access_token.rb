require 'google/api_client'
require 'openssl'

module GoogleSpreadsheets
  module Auth
    class ServiceAccountsAccessToken
      def initialize(options = {})
        @options = options.reverse_merge(
          application_name: 'Ruby',
          token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
          audience:             'https://accounts.google.com/o/oauth2/token',
          scope:                'https://spreadsheets.google.com/feeds/'
        )
      end

      def call(connection)
        # cf. http://d.hatena.ne.jp/sugyan/20130112/1357996092
        @client ||= Google::APIClient.new(application_name: @options[:application_name]).tap do |c|
          c.authorization = Signet::OAuth2::Client.new(
            token_credential_uri: @options[:token_credential_uri],
            audience:             @options[:audience],
            scope:                @options[:scope],
            issuer:               @options[:client_email],
            signing_key:          OpenSSL::PKey::RSA.new(@options[:private_key_pem])
          )
          c.authorization.fetch_access_token!
        end
        if @client.authorization.expired?
          @client.authorization.refresh!
        end
        @client.authorization.access_token
      end
    end
  end
end
