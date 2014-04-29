require './slack-adaptor'
require './twitch-adaptor'
require 'eventmachine'
require 'when'

class Bot
  def startup
    settings = JSON.parse(File.read("settings.json"))
    @sa = SlackAdapator.new(settings)
    @ta = TwitchAdaptor.new
    @streams = []
    @twitch_usernames = []

    refresh_twitch_usernames.then do
      refresh_online_streams
    end

    EventMachine::PeriodicTimer.new(3600) do
      refresh_twitch_usernames
    end

    EventMachine::PeriodicTimer.new(30) do
      refresh_online_streams
    end
  end

  def go
    EventMachine.run do
      startup
    end
  end

  def immediately_and_every(seconds, &block)
    yield
    EventMachine::PeriodicTimer.new(seconds, &block)
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
      @streams = streaming_users
      puts "Refreshed online twitch streams: #{@streams.inspect}"
      deferred.resolver.resolve
    end

    return deferred.promise
  end
end



if $0 == __FILE__
  Bot.new.go
end
