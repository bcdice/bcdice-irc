# frozen_string_literal: true

require_relative 'base'

module BCDiceIRC
  module GUI
    module State
      # 切断済み状態
      class Disconnected < Base
        # 状態を初期化する
        # @param [GUI::Application] app GUIアプリケーション
        def initialize(app)
          super('disconnected', app)

          @hostname_entry_sensitive = true
          @port_spin_button_sensitive = true
          @password_check_button_sensitive = true
          @nick_entry_sensitive = true
          @channel_entry_sensitive = true

          @game_system_combo_box_sensitive = true

          @connect_disconnect_button_label = CONNECT_BUTTON_LABEL
          @connect_disconnect_button_sensitive = true
        end

        # 接続ボタンがクリックされたときの処理
        # @return [void]
        def connect_disconnect_button_on_clicked
          @app.change_state(:connecting)

          @app.update_irc_bot_config
          @app.mediator.start_irc_bot(@app.irc_bot_config)
        end

        # 接続状況表示を更新する
        # @return [void]
        def update_connection_status
          message =
            if @app.last_connection_exception
              "#{@app.irc_bot_config.hostname} に接続できませんでした"
            else
              "#{@app.irc_bot_config.hostname} から切断されました"
            end

          @app.update_connection_status(message)
        end
      end
    end
  end
end
