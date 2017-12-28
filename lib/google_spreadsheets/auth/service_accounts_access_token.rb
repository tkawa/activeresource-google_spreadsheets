require 'googleauth'

module GoogleSpreadsheets
  module Auth
    class ServiceAccountsAccessToken
      def initialize(options = {})
        @options = options
        @options[:scope] ||= 'https://spreadsheets.google.com/feeds/'
      end

      def call(connection)
        @authorizer ||= Google::Auth::ServiceAccountCredentials.make_creds(@options)
        @authorizer.refresh! if @authorizer.expires_at.nil? || @authorizer.expired?
        @authorizer.access_token
      end
    end
  end
end
