# frozen_string_literal: true

require 'cinch'

require 'bcdiceCore'

require_relative '../message_sink'

module BCDiceIRC
  class IRCBot
    module Plugin
      # ダイスコマンドを実行するプラグイン
      class DiceCommand
        include Cinch::Plugin

        self.plugin_name = 'DiceCommand'
        self.help = 'BCDiceのダイスコマンドを実行します'
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
          # ボットに直接送られたメッセージは設定用と見なす
          return if !m.channel || m.target == m.user

          message_sink = MessageSink.new(bot, m.channel, m.user)
          @bcdice.setIrcClient(message_sink)

          @bcdice.setMessage(m.message)
          @bcdice.setChannel(m.channel.name)
          @bcdice.recievePublicMessage(m.user.nick)
        end
      end
    end
  end
end
