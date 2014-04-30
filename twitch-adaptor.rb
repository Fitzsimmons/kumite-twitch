require 'em-http-request'
require 'when'
require 'logger'

require './http-handler'

class TwitchAdaptor
  include HttpHandler

  def initialize
    @logger = Logger.new("log/twitch.log")
  end

  def streaming?(usernames)
    promises = usernames.map do |username|
      deferred = When.defer
      req = EventMachine::HttpRequest.new("https://api.twitch.tv/kraken/streams/#{username}").get

      req.callback do
        logging_non_ok_responses(req, deferred) do
          data = JSON.parse(req.response)
          deferred.resolver.resolve([username, !data['stream'].nil?])
        end
      end

      deferred.promise
    end

    deferred = When.defer
    When.all(promises).then do |values|
      streamers = values.select do |value|
        value[1] == true
      end.map(&:first)
      deferred.resolver.resolve(streamers)
    end

    return deferred.promise
  end
end
