require 'em-http-request'
require 'when'

class TwitchAdaptor
  def streaming?(usernames)
    promises = usernames.map do |username|
      deferred = When.defer
      req = EventMachine::HttpRequest.new("https://api.twitch.tv/kraken/streams/#{username}").get

      req.callback do
        data = JSON.parse(req.response)
        deferred.resolver.resolve([username, !data['stream'].nil?])
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
