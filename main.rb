require './slack-adaptor'

def main
  settings = JSON.parse(File.read("settings.json"))
  sa = SlackAdapator.new(settings)

  users = sa.users
  twitch_users = users.select do |user|
    next false if user['profile']['title'].nil?
    user['profile']['title'].match(/^http:\/\/www\.twitch\.tv/)
  end

  twitch_usernames = twitch_users.map do |tu|
    tu['profile']['title'].match(/^http:\/\/www\.twitch\.tv\/(.*)$/)[1]
  end

  puts twitch_usernames.inspect
end

if $0 == __FILE__
  main
end
