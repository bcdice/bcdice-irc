# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module State
      # GUIの状態の基底クラス
      # @abstract
      class Base
        # 接続ボタンのラベル
        CONNECT_BUTTON_LABEL = 'gtk-connect'
        # 切断ボタンのラベル
        DISCONNECT_BUTTON_LABEL = 'gtk-disconnect'

        # 状態の名前
        # @return [String]
        attr_reader :name

        # メインウィンドウのタイトル
        # @return [String]
        attr_reader :main_window_title

        # 全体的にウィジェットが反応するか
        # @return [Boolean]
        attr_reader :general_widgets_sensitive

        # 接続/切断ボタンのラベル
        # @return [String]
        attr_reader :connect_disconnect_button_label
        # 接続/切断ボタンを押せるか
        # @return [Boolean]
        attr_reader :connect_disconnect_button_sensitive

        # ゲームシステムが変更されたときに通知する必要があるか
        # @return [Boolean]
        attr_reader :need_notification_on_game_system_change

        # 状態を初期化する
        # @param [GUI::Application] app GUIアプリケーション
        # @param [String] name 状態の名前
        def initialize(name, app)
          @name = name
          @app = app

          @main_window_title = @name

          @general_widgets_sensitive = false

          @connect_disconnect_button_label = CONNECT_BUTTON_LABEL
          @connect_disconnect_button_sensitive = false

          @need_notification_on_game_system_change = false
        end

        # 接続状況を返す
        # @return [String]
        def connection_status
          '未接続'
        end

        # 状態に入ったときの処理
        # @return [void]
        def on_enter
          # 既定では何もしない
        end

        # 接続/切断ボタンがクリックされたときの処理
        # @return [void]
        def connect_disconnect_button_on_click
          # 既定では何もしない
        end
      end
    end
  end
end
