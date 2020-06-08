# frozen_string_literal: true

require 'cinch'

require 'bcdiceCore'

require_relative '../irc_message_sink'

require_relative 'utils'

module BCDiceIRC
  module IRCBotPlugin
    # ダイスコマンドを実行するプラグイン
    class DiceCommand
      include Cinch::Plugin
      include Utils

      self.plugin_name = 'DiceCommand'
      self.prefix = ''

      listen_to(:privmsg, method: :on_privmsg)

      # プラグインを初期化する
      def initialize(*)
        super

        @bcdice = config.bcdice
      end

      private

      # PRIVMSGを受信したときの処理
      # @param [Cinch::Message] m メッセージ
      # @return [void]
      def on_privmsg(m)
        return unless channel_message?(m)

        message_sink = IRCMessageSink.new(bot, m.user, config.new_target_proc)
        @bcdice.setIrcClient(message_sink)

        @bcdice.setMessage(m.message)
        @bcdice.setChannel(m.channel.name)
        @bcdice.recievePublicMessage(m.user.nick)
      end
    end
  end
end
