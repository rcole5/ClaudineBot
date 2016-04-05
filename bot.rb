require "cinch"
require "inifile"
require "rubygems"
require "json"
require "open-uri"
require "net/https"
require "rest-client"

# Class for handling links.
class LinkChecker
  include Cinch::Plugin

  # Define variables.
  @@permitLink = Array.new
  @message = Array.new

  # Set prefix to nothing.
  set :prefix, //

  # Set regular expressions and map them to their method.
  match /.*([a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?).*/, method: :isLink
  match /^.*(([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}(?:\-([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]))?).*$/, method: :isLink
  match /.*(https?:\/\/[\S]+).*/, method: :isLink
  match /!permit [A-Za-z0-9_]+/, method: :permit

  # Add user to permit array.
  #
  # m - The message object.
  def permit(m)
    @message = m.message.downcase.split(" ")
    @@permitLink.push(@message[1])
  end

  # Checks to see if the user is a mod in the current channel.
  #
  # m - The message object.
  #
  # Returns true if the user is a mod in the current channel and false if they are not.
  def isMod(m)
    mods = JSON.parse((RestClient.get "http://tmi.twitch.tv/group/user/notaloli/chatters").to_str)
    if mods['chatters']['moderators'].include? m.user.nick
      return true
    else
      return false
    end
  end

  # Checks to see if the user can send a link.
  #
  # m - The message object.
  #
  # Returns true if the user can send a link and false if they can not.
  def canLink(m)

    # Checks if user is a mod. Mods can send links.
    if isMod(m)
      return true
    end
    
    # Checks if the user is permitted to send a link.
    if !@@permitLink.empty?
      if @@permitLink.include? m.user.nick.downcase
        @@permitLink.delete(m.user.nick.downcase)
        return true
      end
    else
      return false
    end
  end

  # Handles if a link is sent.
  def isLink(m)
    # Check if user can link. Timeout if they can not.
    if !canLink(m)
      m.reply("/timeout #{m.user.nick} 15")
      m.reply("No links please, #{m.user.nick}. Please ask a mod before posting a link.")      
    end
  end
end

# Class for if users want to ban themselves.
class Banner
  include Cinch::Plugin

  # Map commands to their methods.
  match "ban", method: :ban
  match "vanish", method: :vanish

  # Timeout the user for 60 sec.
  #
  # m - The message object.
  def ban(m)
    m.reply("/timeout #{m.user.nick} 60")
  end

  # Remove the users messages by timeing them out for 1 second.
  #
  # m - The message object.
  def vanish(m)
    m.reply("/timeout #{m.user.nick} 1")
  end

end

# Initialize the bot.
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
    c.channels = ["#notaloli"]
    c.plugins.plugins = [LinkChecker, Banner]
  end
end

# Start Bot
bot.start
