require "sinatra"

require "facebook/messenger"
include Facebook::Messenger

get "/webhook" do
  params["hub.challenge"] if ENV["VERIFY_TOKEN"] == params["hub.verify_token"]
end

get "/" do
  "Nothing to see here"
end
