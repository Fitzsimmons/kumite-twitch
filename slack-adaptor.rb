require 'rest-client'
require 'json'

class SlackAdapator
  def initialize(options)
    @token = options.fetch('token')
  end

  def users
    JSON.parse(RestClient.get('https://slack.com/api/users.list', params: {token: @token}))['members']
  end
end
