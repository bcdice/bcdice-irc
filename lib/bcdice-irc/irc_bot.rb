# frozen_string_literal: true

require 'forwardable'
require 'cinch'
require_relative 'cinch_mod'

module BCDiceIRC
  class IRCBot
    require_relative 'irc_bot/plugin/dice_command'

    extend Forwardable

    require_relative 'irc_bot/config'

    attr_reader :mediator

    def_delegators(:@bot, :last_connection_error)

    # @param [Config] config 設定
    def initialize(config, mediator)
      @config = config
      @bot = new_bot
      @mediator = mediator
    end

    def start!
      @bot.start
    end

    def quit!
      @bot.quit('Bye!')
    end

    private

    def new_bot
      this = self
      bot = MyCinchBot.new

      timeouts_config = Cinch::Configuration::Timeouts.new
      timeouts_config.connect = 3

      bot.configure do |c|
        c.server = @config.hostname
        c.port = @config.port
        c.reconnect = false
        c.timeouts = timeouts_config
        c.password = @config.password
        c.encoding = 'UTF-8'
        c.nick = @config.nick
        c.user = 'BCDiceIRC'
        c.realname = 'BCDiceIRC'
        c.channels = [@config.channel]

        c.plugins.plugins = [
          Plugin::DiceCommand,
        ]
      end

      bot.loggers.level = :debug

      bot.on(:connect) do
        this.mediator.notify_successfully_connected!
      end

      bot.on(:message, '.version') do |m|
        m.target.send("BCDiceIRC v#{VERSION}", true)
      end

      bot.on(:message, '.quit') do |m|
        this.quit!
      end

      bot
    end
  end
end
