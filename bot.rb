require "cinch"
require "inifile"
require "rubygems"
require "json"
require "open-uri"
require "net/https"
require "rest-client"

# Variable Declaration
permitLink = Array.new


class Hello
  include Cinch::Plugin

  # listen_to :message, 

  match("test")
  def execute(m)
    m.reply "Hello, #{m.user.nick}"
  end
end



def isMod(m)
  mods = JSON.parse((RestClient.get "http://tmi.twitch.tv/group/user/notaloli/chatters").to_str)
  if mods['chatters']['moderators'].include? m.user.nick
    return true
  else
    return false
  end
end

bot = Cinch::Bot.new do

  # Configure bot.
  configure do |c|
    file = IniFile.load('config.ini')
    data = file["User"]
    c.server = "irc.twitch.tv"
    c.port = 6667
    c.nick = data['Username']
    c.user = data['Username']
    c.password = data['Password']
    c.channels = ["#"]
    c.plugins.plugins = [Hello]
  end

  #############################
  # BEGIN LINK AND IP CHECKER #
  #############################

  # Check for link e.g. www.example.com
  on :message, /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix do |m|
    if !isMod(m)
      Channel('#').send("/timeout #{m.user.nick} 1")
      Channel('#').send("No links please, #{m.user.nick}")
    end
  end

  # Check for link e.g. http://example.com
  on :message, /https?:\/\/[\S]+/ do |m|
    if !isMod(m)
      # timeout(m.user.nick)
    end
  end

  # Check for link e.g. 123.123.123.123
  on :message, /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}(?:\-([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))?$/ do |m|
    if !isMod(m)
      # timeout(m.user.nick)
    end
  end

  ###########################
  # END LINK AND IP CHECKER #
  ###########################

  on :message, "!amimod" do |m|
    if isMod(m)
      m.reply "true"
    else
      m.reply "false"
    end
  end


end

# def timeout(username)
#   Channel('#notaloli').send("/timeout #{username} 1")
#   Channel('#notaloli').send("No links please, #{username}")
# end

# Start Bot
bot.start
