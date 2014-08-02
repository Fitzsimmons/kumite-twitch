require './slack-adaptor'
require './twitch-adaptor'
require 'eventmachine'
require 'when'
require 'circular_queue'

def go
  EventMachine.run do

    ta = TwitchAdaptor.new

    promise = ta.streams(['GfinitySC2'])
    promise.then do |streams|
      streams.each do |stream|
        puts "Name: #{stream.username}"
        puts "Game: #{stream.game_name}"

        EventMachine.stop
      end
    end

  end
end

if __FILE__ == $0
  go
end
