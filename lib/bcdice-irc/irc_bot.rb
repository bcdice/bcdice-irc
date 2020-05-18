# frozen_string_literal: true

require 'forwardable'

require 'cinch'
require 'bcdiceCore'

require_relative 'categorizable_logger'

module BCDiceIRC
  # BCDiceのIRCボットのクラス。
  class IRCBot
    extend Forwardable

    # IRCボットとGUIとの仲介
    # @return [GUI::Mediator]
    attr_reader :mediator

    # Cinchボット
    # @return [Cinch::Bot]
    attr_reader :bot

    def_delegators(:@bot, :last_connection_exception)

    # @param [Config] config 設定
    # @param [GUI::Mediator] mediator ボットの処理とGUIの処理との仲介
    # @param [Symbol] log_level ログレベル
    def initialize(config, mediator, log_level)
      @config = config
      @mediator = mediator
      @log_level = log_level

      bcdice_maker = BCDiceMaker.new
      @bcdice = bcdice_maker.newBcDice
      @bot = new_bot

      bcdice_maker.quitFunction = -> { quit! }
      @bcdice.setGameByTitle(@config.game_system_id)
    end

    # IRCボットを起動する
    # @return [Boolean] 接続に成功したか
    def start!
      @bot.start
    end

    # IRCボットを終了する
    # @return [void]
    def quit!
      @bot.quit(@config.quit_message)
    end

    private

    # 新しいCinchボットを作成する
    # @return [Cinch::Bot]
    def new_bot
      this = self
      bot = Cinch::Bot.new

      timeouts_config = Cinch::Configuration::Timeouts.new
      timeouts_config.connect = 3

      bot.configure do |c|
        c.server = @config.hostname
        c.port = @config.port
        c.reconnect = false
        c.timeouts = timeouts_config
        c.password = @config.password
        c.encoding = @config.encoding.encoding
        c.nick = @config.nick
        c.user = 'BCDiceIRC'
        c.realname = 'BCDiceIRC'
        c.channels = [@config.channel]

        c.plugins.plugins = [
          Plugin::IRCChannel,
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

      bot.loggers[0] = CategorizableLogger.new('IRC', $stderr, level: @log_level)

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

require_relative 'irc_bot/encoding'
require_relative 'irc_bot/config'
require_relative 'irc_bot/message_sink'
require_relative 'irc_bot/plugin_config'
require_relative 'irc_bot/plugin'
