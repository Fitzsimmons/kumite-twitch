# encoding: UTF-8

require './slack-adaptor'
require './twitch-adaptor'
require 'eventmachine'
require 'when'
require 'circular_queue'
require 'set'

class Bot
  def setup
    settings = JSON.parse(File.read("settings.json"))
    @sa = SlackAdapator.new(settings)
    @ta = TwitchAdaptor.new
    @streams = CircularQueue.new(2)
    @announced_stream_ids = Set.new
    @twitch_usernames = []
  end

  def go
    EventMachine.run do
      setup

      refresh_twitch_usernames⏲.then do
        refresh_online_streams⏲
      end

      EventMachine::PeriodicTimer.new(3600) do
        refresh_twitch_usernames⏲
      end

      EventMachine::PeriodicTimer.new(60) do
        refresh_online_streams⏲.then do
          notify_of_new_streams
        end
      end

    end
  end

  def notify_of_new_streams
    new_streams = @streams.back - @streams.front

    new_streams.each do |stream|
      unless @announced_stream_ids.include?(stream.id)
        @sa.notify⏲({text: "<http://www.twitch.tv/#{stream.username}> has gone live! (Playing #{stream.game_name})"})
        @announced_stream_ids << stream.id
      end
    end
  end

  def refresh_twitch_usernames⏲
    deferred = When.defer

    promise = @sa.users⏲
    promise.then do |users|
      @twitch_usernames = users.map do |user|
        next nil if user['profile']['title'].nil?
        result = user['profile']['title'].match(/twitch\.tv\/(.*)/)
        next nil if result.nil?
        result[1]
      end
      @twitch_usernames.compact!

      puts "Refreshed twitch usernames: #{@twitch_usernames.inspect}"
      deferred.resolver.resolve
    end

    return deferred.promise
  end

  def refresh_online_streams⏲
    deferred = When.defer

    promise = @ta.streams⏲(@twitch_usernames)
    promise.then do |streams|
      @streams.enq(streams)
      puts "Refreshed online twitch streams: #{streams.map(&:username)}"
      deferred.resolver.resolve
    end

    return deferred.promise
  end
end



if $0 == __FILE__
  Bot.new.go
end
