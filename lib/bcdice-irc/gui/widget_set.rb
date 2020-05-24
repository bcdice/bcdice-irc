# frozen_string_literal: true

module BCDiceIRC
  module GUI
    # ウィジェット集のクラス
    class WidgetSet
      # メインウィンドウ
      # @return [Gtk::Window]
      attr_reader :main_window

      # プリセットコンボボックス
      # @return [Gtk::ComboBox]
      attr_reader :preset_combo_box
      # プリセット名エントリ
      # @return [Gtk::Entry]
      attr_reader :preset_entry
      # プリセット保存ボタン
      # @return [Gtk::Button]
      attr_reader :preset_save_button
      # プリセット削除ボタン
      # @return [Gtk::Button]
      attr_reader :preset_delete_button

      # ホスト名エントリ
      # @return [Gtk::Entry]
      attr_reader :hostname_entry
      # ポート番号スピンボタン
      # @return [Gtk::SpinButton]
      attr_reader :port_spin_button
      # パスワードチェックボタン
      # @return [Gtk::CheckButton]
      attr_reader :password_check_button
      # パスワードエントリ
      # @return [Gtk::Entry]
      attr_reader :password_entry
      # 文字コードコンボボックス
      # @return [Gtk::ComboBox]
      attr_reader :encoding_combo_box
      # ニックネームエントリ
      # @return [Gtk::Entry]
      attr_reader :nick_entry
      # チャンネルエントリ
      # @return [Gtk::Entry]
      attr_reader :channel_entry
      # 接続/切断ボタン
      # @return [Gtk::Button]
      attr_reader :connect_disconnect_button

      # ゲームシステムコンボボックス
      # @return [Gtk::ComboBox]
      attr_reader :game_system_combo_box
      # ヘルプのテキストビュー
      # @return [Gtk::TextView]
      attr_reader :help_text_view

      # バージョン情報ラベル
      # @return [Gtk::Label]
      attr_reader :bcdice_version_label

      # ステータスバー
      # @return [Gtk::StatusBar, nil]
      attr_reader :status_bar

      # @param [Gtk::Builder] builder GUIビルダー
      def initialize(builder)
        @builder = builder
      end

      # ビルダーからウィジェットを読み込む
      # @return [self]
      def load_from_builder
        # メインウィンドウ
        # @return [Gtk::Window]
        @main_window = w('main_window')

        # プリセットコンボボックス
        # @return [Gtk::ComboBox]
        @preset_combo_box = w('preset_combo_box')
        # プリセット名エントリ
        # @return [Gtk::Entry]
        @preset_entry = w('preset_entry')
        # プリセット保存ボタン
        # @return [Gtk::Button]
        @preset_save_button = w('preset_save_button')
        # プリセット削除ボタン
        # @return [Gtk::Button]
        @preset_delete_button = w('preset_delete_button')

        # ホスト名エントリ
        # @return [Gtk::Entry]
        @hostname_entry = w('hostname_entry')
        # ポート番号スピンボタン
        # @return [Gtk::SpinButton]
        @port_spin_button = w('port_spin_button')
        # パスワードチェックボタン
        # @return [Gtk::CheckButton]
        @password_check_button = w('password_check_button')
        # パスワードエントリ
        # @return [Gtk::Entry]
        @password_entry = w('password_entry')
        # 文字コードコンボボックス
        # @return [Gtk::ComboBox]
        @encoding_combo_box = w('encoding_combo_box')
        # ニックネームエントリ
        # @return [Gtk::Entry]
        @nick_entry = w('nick_entry')
        # チャンネルエントリ
        # @return [Gtk::Entry]
        @channel_entry = w('channel_entry')
        # 接続/切断ボタン
        # @return [Gtk::Button]
        @connect_disconnect_button = w('connect_disconnect_button')

        # ゲームシステムコンボボックス
        # @return [Gtk::ComboBox]
        @game_system_combo_box = w('game_system_combo_box')
        # ヘルプのテキストビュー
        # @return [Gtk::TextView]
        @help_text_view = w('help_text_view')

        # バージョン情報ラベル
        # @return [Gtk::Label]
        @bcdice_version_label = w('bcdice_version_label')

        # ステータスバー
        # @return [Gtk::StatusBar]
        @status_bar = w('status_bar')
      end

      private

      # ビルダーから指定されたIDのウィジェットを取得する
      # @param [String] object_id オブジェクトID
      # @return [Gtk::Widget]
      def w(object_id)
        widget = @builder.get_object(object_id)
        raise "widget #{object_id.inspect} not found" unless widget

        widget
      end
    end
  end
end
