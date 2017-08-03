require "facebook/messenger"
require "json"
require "httparty"
include Facebook::Messenger

# map_url = "https://maps.googleapis.com/maps/api/geocode/json"

Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

Bot.on :message do |message|
  puts "Received '#{message.inspect}' from #{message.sender}"
  map_url = "https://maps.googleapis.com/maps/api/geocode/json"
  parsed_response = get_parsed_response(map_url, message.text)
  message.type
  coords = extract_coordinates(parsed_response)
  message.reply(text: coords)
end

def get_parsed_response(url, location)
  response = HTTParty.get(url,
    query: {
      address: location,
      key: ENV["GOOGLE_API_KEY"]
    })
  parsed = JSON.parse(response.body)
  parsed["status"] != "ZERO_RESULTS" ? parsed : nil
end

def extract_coordinates(parsed)
  # parsed["results"].first["geometry"]["location"]

  parsed["results"][0]["geometry"]["bounds"]["northeast"]["lat"].round(1).to_s + ", " +
    parsed["results"][0]["geometry"]["bounds"]["northeast"]["lng"].round(1).to_s
end
