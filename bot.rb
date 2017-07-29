require "facebook/messenger"
require "json"
require "httparty"
include Facebook::Messenger

API_URL = "https://maps.googleapis.com/maps/api/geocode/json?address="

Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

Bot.on :message do |message|
  puts "Received '#{message.inspect}' from #{message.sender}"
  parsed_response = get_parsed_response(API_URL, message.text)
  message.type
  coords = extract_coordinates(parsed_response)
  message.reply(text: "Latitude: #{coord["lat"]}, Longitude: #{coord["lng"]}")
end

def get_parsed_response(url, query)
  response = HTTParty.get(url + query)
  parsed = JSON.parse(response.body)
  parsed["status"] != "ZERO_RESULTS" ? parsed : nil
end

def extract_coordinates(parsed)
  parsed["results"].first["geometry"]["location"]
end
