require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'uri'
require 'json'

class KabukaJob < ApplicationJob
  class_timeout 300 # 300s or 5m, current Lambda max is 15m

  cron "0 1,6 * * 1,2,3,4,5 *" # am 10:00 JST & pm 15:00 JST
  def post
    post_slack get_kabuka
  end

  private

  def get_kabuka
    url = 'https://stocks.finance.yahoo.co.jp/stocks/detail/?code=7068'
    charset = nil

    html = open(url) do |f|
      charset = f.charset
      f.read
    end

    doc = Nokogiri::HTML.parse(html, nil, charset)
    doc.css('.stoksPrice').text.strip
  end

  def post_slack(kabuka)
    uri = URI.parse(ENV['SLACK_WEBHOOK_URL'])
    params = { text: "フィードフォース株価 : #{ kabuka.to_s }" }
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.start do
      request = Net::HTTP::Post.new(uri.path)
      request.set_form_data(payload: params.to_json)
      http.request(request)
    end
  end
end
