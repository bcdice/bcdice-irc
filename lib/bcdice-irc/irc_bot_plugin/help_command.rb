# frozen_string_literal: true

require 'cinch'

require 'bcdiceCore'

require_relative '../irc_message_sink'

module BCDiceIRC
  module IRCBotPlugin
    # ヘルプコマンドを実行するプラグイン
    class HelpCommand
      include Cinch::Plugin

      self.plugin_name = 'HelpCommand'
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
        # ボットに直接送られていないメッセージは設定用と見なさない
        return if m.channel || m.target != m.user

        message_sink = IRCMessageSink.new(bot, m.user, config.new_target_proc)
        @bcdice.setIrcClient(message_sink)

        command, arg = m.message.split('->', 2)

        @bcdice.setMessage(command)
        @bcdice.setChannel(m.user.nick)
        @bcdice.recieveMessage(m.user.nick, arg || '')
      end
    end
  end
end
