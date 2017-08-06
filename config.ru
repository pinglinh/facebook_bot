require "./app"
require_relative "bot1"
# require "dotenv"

# Dotenv.load(".env")

map("/webhook") do
  run Sinatra::Application
  run Facebook::Messenger::Server
end

run Sinatra::Application
