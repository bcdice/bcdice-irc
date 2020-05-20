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

          @main_window_title = '未接続'

          @general_widgets_sensitive = true

          @connect_disconnect_button_label = CONNECT_BUTTON_LABEL
          @connect_disconnect_button_sensitive = true
        end

        # 接続状況を返す
        # @return [String]
        def connection_status
          if @app.last_connection_error
            "#{@app.irc_bot_config.end_point} に接続できませんでした"
          else
            "#{@app.irc_bot_config.end_point} から切断されました"
          end
        end

        # 接続ボタンがクリックされたときの処理
        # @return [void]
        def connect_disconnect_button_on_clicked
          @app.change_state(:connecting)
          @app.mediator.start_irc_bot(@app.irc_bot_config)
        end
      end
    end
  end
end
