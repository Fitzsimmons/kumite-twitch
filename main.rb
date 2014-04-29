require './slack-adaptor'
require './twitch-adaptor'
require 'eventmachine'
require 'when'
require 'circular_queue'

class Bot
  def setup
    settings = JSON.parse(File.read("settings.json"))
    @sa = SlackAdapator.new(settings)
    @ta = TwitchAdaptor.new
    @streams = CircularQueue.new(2)
    @twitch_usernames = []
  end

  def go
    EventMachine.run do
      setup

      refresh_twitch_usernames.then do
        refresh_online_streams
      end

      EventMachine::PeriodicTimer.new(3600) do
        refresh_twitch_usernames
      end

      EventMachine::PeriodicTimer.new(60) do
        refresh_online_streams.then do
          notify_of_new_streams
        end
      end

    end
  end

  def notify_of_new_streams
    new_streams = @streams.back - @streams.front

    new_streams.each do |stream|
      @sa.notify({body: "<http://www.twitch.tv/#{stream}> has gone live!", channel: "#general"})
    end
  end

  def refresh_twitch_usernames
    deferred = When.defer

    promise = @sa.users
    promise.then do |users|
      twitch_users = users.select do |user|
        next false if user['profile']['title'].nil?
        user['profile']['title'].match(/^http:\/\/www\.twitch\.tv/)
      end

      @twitch_usernames = twitch_users.map do |tu|
        tu['profile']['title'].match(/^http:\/\/www\.twitch\.tv\/(.*)$/)[1]
      end
      puts "Refreshed twitch usernames: #{@twitch_usernames.inspect}"
      deferred.resolver.resolve
    end

    return deferred.promise
  end

  def refresh_online_streams
    deferred = When.defer

    promise = @ta.streaming?(@twitch_usernames)
    promise.then do |streaming_users|
      @streams.enq(streaming_users)
      puts "Refreshed online twitch streams: #{streaming_users.inspect}"
      deferred.resolver.resolve
    end

    return deferred.promise
  end
end



if $0 == __FILE__
  Bot.new.go
end
