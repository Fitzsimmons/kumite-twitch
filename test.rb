require './slack-adaptor'
require './twitch-adaptor'
require 'eventmachine'
require 'when'
require 'circular_queue'

def go
  EventMachine.run do

    settings = JSON.parse(File.read("settings.json"))
    puts settings.inspect
    sa = SlackAdapator.new(settings)
    promise = sa.notify⏲({text: "Hello, I am notifying you of something", channel: "@justinf"})

    promise.then do
      EventMachine.stop
    end

  end
end

if __FILE__ == $0
  go
end
