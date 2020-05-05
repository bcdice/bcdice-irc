# frozen_string_literal: true

require_relative 'base'

module BCDiceIRC
  module GUI
    module State
      # 接続中状態
      class Connecting < Base
        # 状態を初期化する
        # @param [GUI::Application] app GUIアプリケーション
        def initialize(app)
          super('connecting', app)

          @hostname_entry_sensitive = false
          @port_spin_button_sensitive = false
          @password_check_button_sensitive = false
          @nick_entry_sensitive = false
          @channel_entry_sensitive = false

          @game_system_combo_box_sensitive = false

          @connect_disconnect_button_label = CONNECT_BUTTON_LABEL
          @connect_disconnect_button_sensitive = false
        end

        # 状態に入ったときの処理
        # @return [void]
        def on_enter
          @app.last_connection_exception = nil
        end

        # 接続/切断ボタンがクリックされたときの処理
        # @return [void]
        # @todo 接続を中断できるようにする
        def connect_disconnect_button_on_clicked
          # 何もしない
        end

        # 接続状況表示を更新する
        # @return [void]
        def update_connection_status
          @app.update_connection_status(
            "#{@app.irc_bot_config.hostname} に接続中..."
          )
        end
      end
    end
  end
end
