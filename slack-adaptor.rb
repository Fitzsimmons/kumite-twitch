# encoding: UTF-8

require 'em-http-request'
require 'when'
require 'json'
require 'logger'

require './http-handler'

class SlackAdapator
  include HttpHandler
  def initialize(options)
    @read_token = options.fetch('read-token')
    @webhook_url = options.fetch('webhook-url')
    @logger = Logger.new("log/slack.log")
  end

  def users⏲
    deferred = When.defer

    req = EventMachine::HttpRequest.new('https://slack.com/api/users.list').get(query: {token: @read_token})

    req.callback do
      logging_non_ok_responses(req, deferred) do
        data = JSON.parse(req.response)
        deferred.resolver.resolve(data['members'])
      end
    end

    return deferred.promise
  end

  def notify⏲(params)
    deferred = When.defer

    payload = {'payload' => JSON.generate(params)}

    req = EventMachine::HttpRequest.new(@webhook_url).post(body: payload)

    req.callback do
      logging_non_ok_responses(req, deferred) do
        deferred.resolver.resolve(req.response)
      end
    end

    return deferred.promise
  end
end
