require 'em-http-request'
require 'when'
require 'logger'

require './http-handler'

class TwitchAdaptor
  include HttpHandler

  class StreamInfo
    def initialize(raw_data)
      @raw_data = raw_data
    end

    def live?
      !@raw_data['stream'].nil?
    end

    def game_name
      return nil unless live?

      @raw_data['stream']['channel']['game']
    end

    def stream_name
      return nil unless live?

      @raw_data['stream']['channel']['status']
    end

    def username
      return nil unless live?

      @raw_data['stream']['channel']['name']
    end
  end

  def initialize
    @logger = Logger.new("log/twitch.log")
  end

  def streams(usernames)
    promises = usernames.map do |username|
      deferred = When.defer
      req = EventMachine::HttpRequest.new("https://api.twitch.tv/kraken/streams/#{username}").get

      req.callback do
        logging_non_ok_responses(req, deferred) do
          data = JSON.parse(req.response)
          stream_info = StreamInfo.new(data)
          deferred.resolver.resolve([username, stream_info])
        end
      end

      deferred.promise
    end

    deferred = When.defer
    When.all(promises).then do |values|
      streams = values.select do |value|
        value[1].live?
      end.map {|pair| pair[1]}
      deferred.resolver.resolve(streams)
    end

    return deferred.promise
  end
end
