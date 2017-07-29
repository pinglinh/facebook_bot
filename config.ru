require "./app"
# require_relative "bot"

map("/webhook") do
  run Sinatra::Application
  run Facebook::Messenger::Server
end

run Sinatra::Application
