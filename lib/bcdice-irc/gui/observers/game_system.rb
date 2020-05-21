# frozen_string_literal: true

require 'observer'

module BCDiceIRC
  module GUI
    module Observers
      # ゲームシステムのオブザーバを格納するモジュール
      module GameSystem
        module_function

        # IRCボット設定のオブザーバを返す
        # @param [IRCBotConfig] config
        # @return [Proc]
        def irc_bot_config(config)
          lambda do |dice_bot_wrapper|
            config.game_system_id = dice_bot_wrapper.id
          end
        end

        # ダイスボットの説明文のテキストビューのオブザーバを返す
        # @param [Gtk::TextView] text_view
        # @return [Proc]
        def help_text_view(text_view)
          lambda do |dice_bot_wrapper|
            text_view.buffer.text = dice_bot_wrapper.help_message
          end
        end

        # メインウィンドウのタイトルのオブザーバを返す
        # @param [Application] app
        # @return [Proc]
        def main_window_title(app)
          lambda do |_|
            app.update_main_window_title
          end
        end

        # ステータスバーのオブザーバを返す
        # @param [Application] app
        # @param [Gtk::StatusBar] bar
        # @param [Integer] context_id
        # @return [Proc]
        def status_bar(app, bar, context_id)
          lambda do |dice_bot_wrapper|
            if app.state.need_notification_on_game_system_change
              bar.push(
                context_id,
                "ゲームシステムを「#{dice_bot_wrapper.name}」に設定しました"
              )
            end
          end
        end
      end
    end
  end
end
