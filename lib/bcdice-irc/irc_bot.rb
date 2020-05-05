# frozen_string_literal: true

require 'forwardable'

require 'cinch'
require_relative 'cinch_mod'

require 'bcdiceCore'

require_relative 'categorizable_logger'
require_relative 'irc_bot/plugin_config'

module BCDiceIRC
  class IRCBot
    require_relative 'irc_bot/plugin/dice_command'
    require_relative 'irc_bot/plugin/master_command'

    extend Forwardable

    require_relative 'irc_bot/config'

    # IRCボットとGUIとの仲介
    # @return [GUI::Mediator]
    attr_reader :mediator

    # Cinchボット
    # @return [Cinch::Bot]
    attr_reader :bot

    def_delegators(:@bot, :last_connection_exception)

    # @param [Config] config 設定
    # @param [GUI::Mediator] mediator ボットの処理とGUIの処理との仲介
    # @param [String] game_system_id ゲームシステムID
    def initialize(config, mediator)
      @config = config
      @mediator = mediator

      bcdice_maker = BCDiceMaker.new
      @bcdice = bcdice_maker.newBcDice
      @bot = new_bot

      bcdice_maker.quitFunction = -> { quit! }
      @bcdice.setGameByTitle(@config.game_system_id)
    end

    def start!
      @bot.start
    end

    def quit!
      @bot.quit(@config.quit_message)
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
          Plugin::MasterCommand,
        ]

        plugin_config = PluginConfig.new(
          bcdice: @bcdice,
          mediator: @mediator
        )
        c.plugins.options = c.plugins.plugins
                             .map { |klass| [klass, plugin_config] }
                             .to_h
      end

      bot.loggers[0] = CategorizableLogger.new('IRC', $stderr, level: @config.log_level)

      bot.on(:connect) do
        this.mediator.notify_successfully_connected
      end

      bot.on(:message, '.version') do |m|
        m.target.send("BCDiceIRC v#{VERSION}", true)
      end

      bot
    end
  end
end
