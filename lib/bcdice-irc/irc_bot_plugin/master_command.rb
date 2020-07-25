# frozen_string_literal: true

require 'forwardable'

require 'cinch'

require 'bcdiceCore'

require_relative '../irc_message_sink'

require_relative 'utils'

module BCDiceIRC
  module IRCBotPlugin
    # マスターコマンドを実行するプラグイン
    #
    # @todo カード読み込み機能を実装する。
    #   この機能では `CardTrader#readExtraCard(cardFileName)` を呼ぶ。
    class MasterCommand
      include Cinch::Plugin
      include Utils
      extend Forwardable

      self.plugin_name = 'MasterCommand'
      self.prefix = ''

      match(/\Aset\s+master(?:->(#{NICK_RE}))?/io, method: :set_master)
      match(/\Aset\s+game->([!&. \w]+)/i, method: :set_game_system)
      match(/\Aset\s+upper->(\d+)/i, method: :set_upper_roll_threshold)
      match(/\Aset\s+reroll->(\d+)/i, method: :set_reroll_limit)
      match(/\Aset\s+sort->([0-3])/i, method: :set_sort_mode)
      match(/\Aset\s+viewmode->([0-2])/i, method: :set_view_mode)
      match(/\Aset\s+cardplace->([01])/i, method: :set_card_place)
      match(/\Aset\s+tap->([01])/i, method: :set_can_tap_card)
      match(/\Amode\z/i, method: :print_mode)

      listen_to(:privmsg, method: :on_privmsg)

      # @!attribute [r] dice_bot
      #   @return [DiceBot] BCDiceに設定されたダイスボット
      def_delegator(:@bcdice, :diceBot, :dice_bot)

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

      # ユーザーがマスターかを返す
      # @param [Cinch::User] user ユーザー
      # @return [Boolean]
      def master?(user)
        user.nick.downcase == @master&.downcase
      end

      # 設定変更を行えるかを返す
      # @param [Cinch::User] user ユーザー
      # @return [Boolean]
      def setting_permitted?(user)
        !@master || master?(user)
      end

      # マスター設定コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @param [String, nil] value 新しい値
      # @return [void]
      def set_master(m, value)
        return unless direct_message?(m)

        unless setting_permitted?(m.user)
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

        response =
          if @master
            "#{@master}さんをMasterに設定しました"
          else
            "Master設定を解除しました"
          end

        broadcast(response)
      end

      # 上方無限ロールの境界値設定コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @param [String] value_s 新しい値
      # @return [void]
      def set_upper_roll_threshold(m, value_s)
        return unless setting_permitted?(m.user)

        value = value_s.to_i
        dice_bot.upperRollThreshold = value

        response =
          if value > 0
            "上方無限ロールを#{value}以上に設定しました"
          else
            '上方無限ロールの閾値設定を解除しました'
          end

        broadcast(response)
      end

      # 個数振り足しロールの回数制限設定コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @param [String] value_s 新しい値
      # @return [void]
      def set_reroll_limit(m, value_s)
        return unless setting_permitted?(m.user)

        value = value_s.to_i
        dice_bot.rerollLimitCount = value

        response =
          if value > 0
            "個数振り足しロール回数を#{value}以下に設定しました"
          else
            "個数振り足しロールの回数を無限に設定しました"
          end

        broadcast(response)
      end

      # 出目表示の並び替え設定コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @param [String] value_s 新しい値
      # @return [void]
      def set_sort_mode(m, value_s)
        return unless setting_permitted?(m.user)

        value = value_s.to_i
        dice_bot.setSortType(value)

        broadcast(
          value > 0 ? 'ソート有りに変更しました' : 'ソート無しに変更しました'
        )
      end

      # ダイスロール結果の表示設定コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @param [String] value_s 新しい値
      # @return [void]
      def set_view_mode(m, value_s)
        return unless setting_permitted?(m.user)

        value = value_s.to_i
        dice_bot.setSendMode(value)

        broadcast("ViewMode#{value}に変更しました")
      end

      # カード置き場の有無設定コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @param [String] value_s 新しい値
      # @return [void]
      def set_card_place(m, value_s)
        return unless setting_permitted?(m.user)

        value = value_s.to_i
        @bcdice.cardTrader.card_place = value

        response =
          if value == 0
            'カード置き場無しに変更しました'
          else
            'カード置き場ありに変更しました'
          end

        broadcast(response)
      end

      # カード置き場の有無設定コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @param [String] value_s 新しい値
      # @return [void]
      def set_can_tap_card(m, value_s)
        return unless setting_permitted?(m.user)

        value = value_s.to_i != 0
        @bcdice.cardTrader.canTapCard = value

        response =
          if value
            'タップ可能モードに変更しました'
          else
            'タップ不可モードに変更しました'
          end

        broadcast(response)
      end

      # ゲームシステム変更コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @param [String] game_system_id ゲームシステムID
      # @return [void]
      def set_game_system(m, game_system_id)
        return unless direct_message?(m)

        @bcdice.setGameByTitle(game_system_id)

        @mediator.notify_game_system_has_been_changed(dice_bot.id)
        broadcast("Game設定を#{dice_bot.name}に設定しました")
      end

      # モード確認コマンドに対応する処理
      # @param [Cinch::Message] m メッセージ
      # @return [void]
      def print_mode(m)
        return unless direct_message?(m) && setting_permitted?(m.user)

        parts = [
          "GameType = #{dice_bot.id}",
          "ViewMode = #{dice_bot.sendMode}",
          "Sort = #{dice_bot.sortType}",
        ]

        m.user.notice(parts.join(', '))
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
