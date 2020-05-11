# frozen_string_literal: true

require_relative 'base'

module BCDiceIRC
  module GUI
    module State
      # 接続中状態
      class Disconnecting < Base
        # 状態を初期化する
        # @param [GUI::Application] app GUIアプリケーション
        def initialize(app)
          super('disconnecting', app)

          @main_window_title = '切断中...'

          @hostname_entry_sensitive = false
          @port_spin_button_sensitive = false
          @password_check_button_sensitive = false
          @encoding_combo_box_sensitive = false
          @nick_entry_sensitive = false
          @channel_entry_sensitive = false

          @game_system_combo_box_sensitive = false

          @connect_disconnect_button_label = DISCONNECT_BUTTON_LABEL
          @connect_disconnect_button_sensitive = false
        end

        # 接続状況を返す
        # @return [String]
        def connection_status
          "#{@app.irc_bot_config.end_point} から切断中..."
        end
      end
    end
  end
end
