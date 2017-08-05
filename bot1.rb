require "facebook/messenger"
require "httparty"
require "json"
require "pry"
include Facebook::Messenger

Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

API_URL = "https://maps.googleapis.com/maps/api/geocode/json?address=".freeze

def wait_for_user_input
  Bot.on :message do |message|
    case message.text
    when /coord/i, /gps/i
      message.reply(text: "Enter destination")
      process_coordinates
    end
  end
end

def process_coordinates
  Bot.on :message do |message|
    parsed_response = get_parsed_response(API_URL, message.text)
    if !parsed_response
      message.reply(text: "There were no results. Ask me again, please")
      wait_for_user_input
      return
    end
    message.typing_on
    coord = extract_coordinates(parsed_response)
    message.reply(text:
      "Latitude: #{coord["lat"]} /
      Longitude: #{coord["lng"]}"
      )
    wait_for_user_input
  end
end

def get_parsed_response(url, query)
  response = HTTParty.get(url + query)
  parsed = JSON.parse(response.body)
  parsed["status"] != "ZERO_RESULTS" ? parsed : nil
end

def extract_coordinates(parsed)
  parsed["results"].first["geometry"]["location"]
end

binding.pry

wait_for_user_input
