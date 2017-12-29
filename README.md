# ActiveResource GoogleSpreadsheets

Google Spreadsheets accessor with ActiveResource

http://webos-goodies.jp/archives/active_resource_google_spreadsheets_data_api.html

## Installation

Add this line to your application's Gemfile:

    gem 'activeresource-google_spreadsheets'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activeresource-google_spreadsheets

## Usage

http://webos-goodies.jp/archives/active_resource_google_spreadsheets_data_api.html

### Authorization example (Service Account)

#### 1. Using JSON key file

in `config/initializers/google_spreadsheet.rb`

```ruby
GoogleSpreadsheets::Base.auth_type = :bearer
GoogleSpreadsheets::Base.access_token =
  GoogleSpreadsheets::Auth::ServiceAccountsAccessToken.new(
    json_key_io: File.open('/path/to/service_account_json_key.json')
  )
```

#### 2. Using client email & private key

in `config/initializers/google_spreadsheet.rb`

```ruby
GoogleSpreadsheets::Base.auth_type = :bearer
GoogleSpreadsheets::Base.access_token =
  GoogleSpreadsheets::Auth::ServiceAccountsAccessToken.new
```
and set the values to `ENV['GOOGLE_CLIENT_EMAIL']` & `ENV['GOOGLE_PRIVATE_KEY']`


### ActiveRecord Syncing Feature (Experimental)

http://qiita.com/tkawa/items/04fc6f0574122d4a3fd2

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
