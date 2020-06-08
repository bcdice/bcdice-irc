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

      # ニックネームとして指定可能な文字のパターン
      #
      # Charybdisを参考にした。
      #
      # 最初の文字は、数字および `'-'` 以外。
      #
      # @see https://github.com/charybdis-ircd/charybdis/blob/charybdis-4.1.2/ircd/client.c#L903-L933
      # @see https://github.com/charybdis-ircd/charybdis/blob/charybdis-4.1.2/include/match.h#L118
      # @see https://github.com/charybdis-ircd/charybdis/blob/charybdis-4.1.2/ircd/match.c#L659-L793
      NICK_RE = /[A-Z\[\\\]^_`a-z{|}][-0-9A-Z\[\\\]^_`a-z{|}]*/

      match(/\Aset\s+master(?:->(#{NICK_RE}))?/io, method: :set_master)
      match(/\Aset\s+game->([!&. \w]+)/i, method: :set_game_system)

      listen_to(:privmsg, method: :on_privmsg)

      # プラグインを初期化する
      def initialize(*)
        super

        @bcdice = config.bcdice
        @mediator = config.mediator

        # マスターのニックネーム
        # @type [String, nil]
        @master = nil
      end

      private

      # マスター設定コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @param [String, nil] value 新しい値
      # @return [void]
      def set_master(m, value)
        return unless direct_message?(m)

        if @master && m.user.nick.downcase != @master.downcase
          m.user.notice("Masterは#{@master}さんになっています")
          return
        end

        if value
          @master = value
        else
          # 既にマスターが設定されていれば設定解除する
          # 設定されていなかった場合は、送信者をマスターとして設定する
          @master = @master ? nil : m.user.nick
        end

        broadcast(response_to_set_master(@master))
      end

      # マスター設定コマンドに対する応答を返す
      # @param [String, nil] master 設定後のマスターのニックネーム
      # @return [String]
      def response_to_set_master(master)
        if master
          "#{master}さんをMasterに設定しました"
        else
          "Master設定を解除しました"
        end
      end

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
