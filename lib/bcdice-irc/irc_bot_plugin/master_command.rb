# frozen_string_literal: true

require 'cinch'

require 'bcdiceCore'

require_relative '../irc_message_sink'

require_relative 'utils'

module BCDiceIRC
  module IRCBotPlugin
    # マスターコマンドを実行するプラグイン
    class MasterCommand
      include Cinch::Plugin
      include Utils

      self.plugin_name = 'MasterCommand'
      self.prefix = ''

      match(/\Aset\s+game->([!&. \w]+)/i, method: :set_game_system)

      listen_to(:privmsg, method: :on_privmsg)

      # プラグインを初期化する
      def initialize(*)
        super

        @bcdice = config.bcdice
        @mediator = config.mediator
      end

      private

      # ゲームシステム変更コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @param [String] game_system_id ゲームシステムID
      # @return [void]
      def set_game_system(m, game_system_id)
        return unless direct_message?(m)

        @bcdice.setGameByTitle(game_system_id)
        new_dice_bot = @bcdice.diceBot

        @mediator.notify_game_system_has_been_changed(new_dice_bot.id)
        broadcast("Game設定を#{new_dice_bot.name}に設定しました")
      end

      # PRIVMSGを受信したときの処理
      # @param [Cinch::Message] m メッセージ
      # @return [void]
      def on_privmsg(m)
        return unless direct_message?(m)

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
