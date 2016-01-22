require 'bundler/setup'
require 'sinatra/base'
require 'omniauth-shopify-oauth2'
require 'aws-sdk'

SCOPE = 'read_products,read_orders,read_customers,write_shipping'
SHOPIFY_API_KEY = ENV['SHOPIFY_API_KEY']
SHOPIFY_SHARED_SECRET = ENV['SHOPIFY_SHARED_SECRET']
COGNITO_POOL_ID = ENV['COGNITO_POOL_ID']

unless SHOPIFY_API_KEY && SHOPIFY_SHARED_SECRET
  abort("SHOPIFY_API_KEY and SHOPIFY_SHARED_SECRET environment variables must be set")
end

class App < Sinatra::Base
  get '/' do
    <<-HTML
    <html>
    <head>
      <title>Shopify Oauth2</title>
    </head>
    <body>
      <form action="/auth/shopify" method="get">
      <label for="shop">Enter your store's URL:</label>
      <input type="text" name="shop" placeholder="your-shop-url.myshopify.com">
      <button type="submit">Log In</button>
      </form>
    </body>
    </html>
    HTML
  end

  get '/auth/:provider/callback' do
    client = Aws::CognitoIdentity::Client.new
    cognito_response = client.get_open_id_token_for_developer_identity({
      identity_pool_id: COGNITO_POOL_ID, # required
      # identity_id: "IdentityId", # to locate existent customer
      logins: { # required
        "co.bdhr.shopify-identity" => request.env['omniauth.auth'].uid,
      },
      token_duration: 1,
    })

    # NOTE: it could be CloudFront URL
    # TODO: token is quite long, perhaps good idea would be store it in the
    # session of authentication backend and then client-side appliction could
    # pull it after redirect
    # redirect "/shopify-app.html#auth" # triggers the authentication callback on client-side
    redirect "/shopify-app.html?token=#{cognito_response.token}&identity_id=#{cognito_response.identity_id}&pool_id=#{COGNITO_POOL_ID}"
  end

  get '/auth/failure' do
    <<-HTML
    <html>
    <head>
      <title>Shopify Oauth2</title>
    </head>
    <body>
      <h3>Failed Authorization</h3>
      <p>Message: #{params[:message]}</p>
    </body>
    </html>
    HTML
  end
end

use Rack::Session::Cookie, secret: SecureRandom.hex(64)

use OmniAuth::Builder do
  provider :shopify, SHOPIFY_API_KEY, SHOPIFY_SHARED_SECRET, :scope => SCOPE
end

run App.new
