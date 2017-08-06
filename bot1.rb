require "facebook/messenger"
require "httparty"
require "json"
require "addressable/uri"
include Facebook::Messenger

Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

API_URL = "https://maps.googleapis.com/maps/api/geocode/json?address="

REVERSE_API_URL = "https://maps.googleapis.com/maps/api/geocode/json?latlng="

IDIOMS = {
  not_found: "There were no results. Ask me again, please",
  ask_location: "Enter destination",
  unknown_command: "Sorry, I did not recognize your command",
  menu_greeting: "What do you want to look up?"
}.freeze

MENU_REPLIES = [
  {
    content_type: 'text',
    title: 'GPS for address',
    payload: 'COORDINATES'
  },
  {
    content_type: 'text',
    title: 'Full address',
    payload: 'FULL_ADDRESS'
  },
  {
    content_type: "text",
    title: "My location",
    payload: "LOCATION"
  }
]

TYPE_LOCATION = [{ content_type: 'location' }]

Facebook::Messenger::Thread.set({
  setting_type: 'call_to_actions',
  thread_state: 'new_thread',
  call_to_actions: [
    {
      payload: 'START'
    }
  ]
}, access_token: ENV['ACCESS_TOKEN'])

# Create persistent menu
Facebook::Messenger::Thread.set({
  setting_type: 'call_to_actions',
  thread_state: 'existing_thread',
  call_to_actions: [
    {
      type: "postback",
      title: "Coordinates lookup",
      payload: "COORDINATES"
    },
    {
      type: 'postback',
      title: 'Postal address lookup',
      payload: 'FULL_ADDRESS'
    },
    {
      type: 'postback',
      title: 'Location lookup',
      payload: 'LOCATION'
    }
  ]
}, access_token: ENV['ACCESS_TOKEN'])

# Set greeting (for first contact)
Facebook::Messenger::Thread.set({
  setting_type: 'greeting',
  greeting: {
    text: 'Coordinator welcomes you!'
  },
}, access_token: ENV['ACCESS_TOKEN'])






Bot.on :postback do |postback|
  sender_id = postback.sender['id']
  case postback.payload
  when 'START' then show_replies_menu(postback.sender['id'], MENU_REPLIES)
  when 'COORDINATES'
    say(sender_id, IDIOMS[:ask_location], TYPE_LOCATION)
    show_coordinates(sender_id)
  when 'FULL_ADDRESS'
    say(sender_id, IDIOMS[:ask_location], TYPE_LOCATION)
    show_full_address(sender_id)
  when "LOCATION"
    lookup_location(sender_id)
  end
end

def wait_for_any_input
  Bot.on :message do |message|
    show_replies_menu(message.sender["id"], MENU_REPLIES)
  end
end

def say(recipient_id, text, quick_replies = nil)
  message_options = {
    recipient: {
      id: recipient_id
    },
    message: {
      text: text
    }
  }
  if quick_replies
    message_options[:message][:quick_replies] = quick_replies
  end
  Bot.deliver(message_options, access_token: ENV["ACCESS_TOKEN"])
end

def show_replies_menu(id, quick_replies)
  say(id, IDIOMS[:menu_greeting], quick_replies)
  wait_for_command
end

def wait_for_command
  Bot.on :message do |message|
    puts "Received '#{message.inspect}' from #{message.sender}"
    sender_id = message.sender['id']
    case message.text
    when /coord/i, /gps/i
      say(sender_id, IDIOMS[:ask_location], TYPE_LOCATION)
      show_coordinates(sender_id)
    when /full ad/i
      say(sender_id, IDIOMS[:ask_location], TYPE_LOCATION)
      show_full_address(sender_id)
    when /location/i
      lookup_location(sender_id)
    else
      message.reply(text: IDIOMS[:unknown_command])
      show_replies_menu(sender_id, MENU_REPLIES)
    end
  end
end

def lookup_location(sender_id)
  say(sender_id, 'Let me know your location:', TYPE_LOCATION)
  Bot.on :message do |message|
    if message_contains_location?(message)
      handle_user_location(message)
    else
      message.reply(text: "Please try your request again and use 'Send location' button")
    end
    wait_for_any_input
  end
end

def message_contains_location?(message)
  if attachments = message.attachments
    attachments.first['type'] == 'location'
  else
    false
  end
end

def handle_user_location(message)
  coords = message.attachments.first['payload']['coordinates']
  lat = coords['lat']
  long = coords['long']
  message.type
  parsed = get_parsed_response(REVERSE_API_URL, "#{lat},#{long}")
  address = extract_full_address(parsed)
  message.reply(text: "Coordinates of your location: Latitude #{lat}, Longitude #{long}. Looks like you're at #{address}.")
  wait_for_any_input
end

def process_coordinates(id)
  handle_api_request do |api_response, message|
    coord = extract_coordinates(api_response)
    message.reply(text:
      "Latitude: #{coord["lat"]} / Longitude: #{coord["lng"]}"
      )
  end
end

def show_coordinates(id)
  Bot.on :message do |message|
    if message_contains_location?(message)
      handle_user_location(message)
    else
      handle_coordinates_lookup(message, id)
    end
  end
end

def handle_coordinates_lookup(message, id)
  query = encode_ascii(message.text)
  parsed_response = get_parsed_response(API_URL, query)
  message.type
  if parsed_response
    coord = extract_coordinates(parsed_response)
    text = "Latitude: #{coord["lat"]} / Longitude: #{coord["lng"]}"
    say(id, text)
    wait_for_any_input
  else
    message.reply(text: IDIOMS[:not_found])
    show_coordinates
  end
end

def show_full_address(id)
  Bot.on :message do |message|
    if message_contains_location?(message)
      handle_user_location(message)
    else
      if !is_text_message?(message)
        say(id, "Why are you trying to fool me, human?")
        wait_for_any_input
      else
        handle_address_lookup(message, id)
      end
    end
  end
end

def handle_address_lookup(message, id)
  query = encode_ascii(message.text)
  parsed_response = get_parsed_response(API_URL, query)
  message.type
  if parsed_response
    full_address = extract_full_address(parsed_response)
    say(id, full_address)
    wait_for_any_input
  else
    message.reply(text: IDIOMS[:not_found])
    show_full_address(id)
  end
end

def encode_ascii(s)
  Addressable::URI.parse(s).normalize.to_s
end

def get_parsed_response(url, query)
  response = HTTParty.get(url + query)
  parsed = JSON.parse(response.body)
  parsed["status"] != "ZERO_RESULTS" ? parsed : nil
end

def extract_full_address(parsed)
  parsed["results"][0]["formatted_address"]
end

def extract_coordinates(parsed)
  parsed["results"][0]["geometry"]["location"]
end

def is_text_message?(message)
  !message.text.nil?
end

wait_for_any_input
