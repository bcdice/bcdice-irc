# frozen_string_literal: true

require 'observer'

module BCDiceIRC
  module GUI
    # ゲームシステムのオブザーバを格納するモジュール
    module GameSystemObserver
      module_function

      def irc_bot_config(config)
        lambda do |dice_bot_wrapper|
          config.game_system_id = dice_bot_wrapper.id
        end
      end

      def help_text_view(text_view)
        lambda do |dice_bot_wrapper|
          text_view.buffer.text = dice_bot_wrapper.help_message
        end
      end

      def main_window_title(app)
        lambda do |_|
          app.update_main_window_title
        end
      end

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
