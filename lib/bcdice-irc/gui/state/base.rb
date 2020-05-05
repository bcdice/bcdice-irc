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
        attr_reader :name

        # ホスト名を入力できるか
        # @return [Boolean]
        attr_reader :hostname_entry_sensitive
        # ポート番号を入力できるか
        # @return [Boolean]
        attr_reader :port_spin_button_sensitive
        # パスワードを入力できるか
        # @return [Boolean]
        attr_reader :password_check_button_sensitive
        # ニックネームを入力できるか
        # @return [Boolean]
        attr_reader :nick_entry_sensitive
        # チャンネルを入力できるか
        # @return [Boolean]
        attr_reader :channel_entry_sensitive

        # ゲームシステムを設定できるか
        # @return [Boolean]
        attr_reader :game_system_combo_box_sensitive

        # 接続/切断ボタンのラベル
        # @return [String]
        attr_reader :connect_disconnect_button_label
        # 接続/切断ボタンを押せるか
        # @return [Boolean]
        attr_reader :connect_disconnect_button_sensitive

        # 状態を初期化する
        # @param [GUI::Application] app GUIアプリケーション
        # @param [String] name 状態の名前
        def initialize(name, app)
          @name = name
          @app = app

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
          # 既定では何もしない
        end

        # 接続/切断ボタンがクリックされたときの処理
        # @return [void]
        def connect_disconnect_button_on_click
          # 既定では何もしない
        end

        # 接続状況を返す
        # @return [String]
        def connection_status
          '未接続'
        end
      end
    end
  end
end
