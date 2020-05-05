# frozen_string_literal: true

require_relative 'base'

module BCDiceIRC
  module GUI
    module State
      # 接続済み状態
      class Connected < Base
        # 状態を初期化する
        # @param [GUI::Application] app GUIアプリケーション
        def initialize(app)
          super('connected', app)

          @hostname_entry_sensitive = false
          @port_spin_button_sensitive = false
          @password_check_button_sensitive = false
          @nick_entry_sensitive = false
          @channel_entry_sensitive = false

          @game_system_combo_box_sensitive = false

          @connect_disconnect_button_label = DISCONNECT_BUTTON_LABEL
          @connect_disconnect_button_sensitive = true
        end

        # 切断ボタンがクリックされたときの処理
        # @return [void]
        def connect_disconnect_button_on_clicked
          @app.change_state(:disconnecting)
          @app.mediator.quit_irc_bot
        end

        # 接続状況を返す
        # @return [String]
        def connection_status
          "#{@app.end_point} に接続しました"
        end
      end
    end
  end
end
