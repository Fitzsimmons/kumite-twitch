require 'em-http-request'
require 'when'
require 'json'

class SlackAdapator
  def initialize(options)
    @token = options.fetch('token')
  end

  def users
    deferred = When.defer

    req = EventMachine::HttpRequest.new('https://slack.com/api/users.list').get(query: {token: @token})

    req.callback do
      data = JSON.parse(req.response)
      deferred.resolver.resolve(data['members'])
    end

    return deferred.promise
  end
end
