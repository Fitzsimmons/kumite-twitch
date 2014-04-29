require 'em-http-request'
require 'when'
require 'json'

class SlackAdapator
  def initialize(options)
    @read_token = options.fetch('read-token')
    @write_token = options.fetch('write-token')
  end

  def users
    deferred = When.defer

    req = EventMachine::HttpRequest.new('https://slack.com/api/users.list').get(query: {token: @read_token})

    req.callback do
      data = JSON.parse(req.response)
      deferred.resolver.resolve(data['members'])
    end

    return deferred.promise
  end

  def notify(params)
    deferred = When.defer

    payload = {'payload' => JSON.generate(params)}

    req = EventMachine::HttpRequest.new("https://kumite.slack.com/services/hooks/incoming-webhook").post(body: payload, query: {token: @write_token})

    req.callback do
      deferred.resolver.resolve(req.response)
    end

    return deferred.promise
  end
end
