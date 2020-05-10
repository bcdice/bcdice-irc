# frozen_string_literal: true

require 'gtk3'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/object/blank'

require 'cinch/logger/formatted_logger'

require 'bcdiceCore'
require 'diceBot/DiceBot'
require 'diceBot/DiceBotLoader'

require_relative '../version'
require_relative '../dice_bot_wrapper'
require_relative '../irc_bot'
require_relative '../categorizable_logger'

require_relative 'mediator'
require_relative 'state'
require_relative 'preset_manager'

module BCDiceIRC
  module GUI
    class Application
      # ログレベル
      # @return [Symbol]
      attr_reader :log_level

      # IRCボットの設定
      # @return [IRCBot::Config]
      attr_accessor :irc_bot_config
      # ダイスボットラッパ
      # @return [DiceBotWrapper]
      attr_reader :dice_bot_wrapper
      # IRCボットとGUIとの仲介
      # @return [GUI::Mediator]
      attr_reader :mediator

      # 最後に発生した接続エラー
      # @return [StandardError, nil]
      attr_accessor :last_connection_exception

      attr_reader :hostname_entry
      attr_reader :port_spin_button
      attr_reader :password_check_button
      attr_reader :password_entry
      attr_reader :nick_entry
      attr_reader :channel_entry

      # アプリケーションを初期化する
      # @param [String] presets_yaml_path プリセット集のYAMLファイルのパス
      # @param [Symbol] log_level ログレベル
      def initialize(presets_yaml_path, log_level)
        @presets_yaml_path = presets_yaml_path
        @log_level = log_level

        @builder = Gtk::Builder.new

        @use_password = false
        @dice_bot_wrapper = nil
        @preset_manager = nil
        @irc_bot_config = IRCBot::Config::DEFAULT.deep_dup
        @last_connection_exception = nil

        @setting_up = false
        @states = {
          disconnected: State::Disconnected.new(self),
          connecting: State::Connecting.new(self),
          connected: State::Connected.new(self),
          disconnecting: State::Disconnecting.new(self),
        }
        @state = nil

        @logger = CategorizableLogger.new('Application', $stderr, level: @log_level)
        @mediator = Mediator.new(self, @log_level)
      end

      # 接続先のエンドポイント（+ホスト名:ポート+）を返す
      # @return [String]
      def end_point
        if @irc_bot_config
          "#{@irc_bot_config.hostname}:#{@irc_bot_config.port}"
        else
          ''
        end
      end

      # アプリケーションを実行する
      # @return [self]
      def start!
        @logger.debug('Setup start')

        @setting_up = true

        collect_dice_bots
        setup_preset_manager

        load_glade_file
        setup_widgets
        change_state(:disconnected)
        set_last_selected_preset
        @main_window.show_all

        @setting_up = false

        @logger.debug('Setup end')

        @logger.debug('Start mediator')
        @mediator.start!

        @logger.debug('Main loop start')
        Gtk.main
        @logger.debug('Main loop end')

        self
      end

      # パスワードを使うかどうかを変更する
      # @param [Boolean] value パスワードを使うか
      # @note ウィジェットの準備が完了してから使うこと。
      def use_password=(value)
        @use_password = value
        @irc_bot_config.password = @use_password ? @password_entry.text : nil

        @password_entry.sensitive =
          @state.password_check_button_sensitive && @use_password
      end

      # ダイスボットラッパを変更する
      # @param [DiceBotWrapper] value 新しいダイスボットラッパ
      # @note ウィジェットの準備が完了してから使うこと。
      def dice_bot_wrapper=(value)
        @dice_bot_wrapper = value

        @help_text_view.buffer.text = @dice_bot_wrapper.help_message
        update_main_window_title

        if @state.need_notification_on_game_system_change
          @status_bar.push(
            @status_bar_context_ids.fetch(:game_system_change),
            "ゲームシステムを「#{@dice_bot_wrapper.name}」に設定しました"
          )
        end
      end

      # ゲームシステムをIDで指定して変更する
      #
      # ゲームシステムIDに対応するダイスボットラッパが設定される。
      # 対応するダイスボットラッパが見つからなかった場合には何もしない。
      #
      # @param [String] value 新しいゲームシステムID
      # @note ウィジェットの準備が完了してから使うこと。
      def game_system_id=(value)
        new_index = @id_to_dice_bot_wrapper_index[value]
        return unless new_index

        @game_system_combo_box.active = new_index
      end

      # ゲームシステムを名前で指定して変更する
      #
      # ゲームシステム名に対応するダイスボットラッパが設定される。
      # 対応するダイスボットラッパが見つからなかった場合には何もしない。
      #
      # @param [String] value 新しいゲームシステム名
      # @note ウィジェットの準備が完了してから使うこと。
      def game_system_name=(value)
        new_index = @name_to_dice_bot_wrapper_index[value]
        return unless new_index

        @game_system_combo_box.active = new_index
      end

      # アプリケーションの状態を変更する
      # @param [Symbol] id 状態のID
      # @return [self]
      def change_state(id)
        self.state = @states.fetch(id)
        self
      end

      # プリセットからIRCボット設定を設定する
      # @param [IRCBot::Config] irc_bot_config プリセットのIRCボット設定
      # @return [self]
      def set_irc_bot_config_from_preset(irc_bot_config)
        # TODO: ここからバリデーションを無効にする

        @hostname_entry.text = irc_bot_config.hostname
        @port_spin_button.value = irc_bot_config.port

        if irc_bot_config.password
          @password_check_button.active = true
          @password_entry.text = irc_bot_config.password
        else
          @password_check_button.active = false
          @password_entry.text = ''
        end

        @nick_entry.text = irc_bot_config.nick
        @channel_entry.text = irc_bot_config.channel

        # TODO: バリデーション無効化ここまで。ここでバリデーションを実行する。

        @irc_bot_config.quit_message = irc_bot_config.quit_message.dup
        self.game_system_id = irc_bot_config.game_system_id

        @status_bar.push(
          @status_bar_context_ids.fetch(:preset_load),
          "プリセット「#{irc_bot_config.name}」を読み込みました"
        )

        self
      end

      # メインウィンドウのタイトルを更新する
      # @return [self]
      # @note ウィジェットの準備が完了してから使うこと。
      def update_main_window_title
        @main_window.title = "#{@state.main_window_title} - BCDice IRC"
        self
      end

      # 接続状況表示を更新する
      # @return [self]
      # @note ウィジェットの準備が完了してから使うこと。
      def update_connection_status
        return if @setting_up

        @status_bar.push(
          @status_bar_context_ids.fetch(:connection),
          @state.connection_status
        )

        self
      end

      # 接続エラーを通知する
      # @param [StandardError] e 接続時に発生した例外
      # @return [self]
      def notify_connection_error(e)
        @last_connection_exception = e
        change_state(:disconnected)
        show_connection_error_dialog(e)

        self
      end

      # 接続エラーダイアログを表示する
      # @param [StandardError] e 発生した例外
      # @return [self]
      def show_connection_error_dialog(e)
        message_utf8 = e.message.encode('UTF-8', invalid: :replace, undef: :replace)
        dialog = Gtk::MessageDialog.new(
          parent: @main_window,
          flags: :destroy_with_parent,
          type: :error,
          buttons: :ok,
          message: "#{@irc_bot_config.hostname} に接続できませんでした:\n#{message_utf8}"
        )
        dialog.run
        dialog.destroy

        self
      end

      # GUIスレッドのアイドル時間に、ブロックで与えられた処理を行う
      # @return [void]
      def in_idle_time
        GLib::Idle.add do
          yield
          false
        end
      end

      private

      # アプリケーションの状態を変更する
      # @param [GUI::State::Base] 新しい状態
      # @note ウィジェットの準備が完了してから使うこと。
      def state=(value)
        @state = value

        update_main_window_title
        update_widgets

        @logger.info("State -> #{@state.name}")
      end

      # ダイスボットを収集し、キャッシュする
      # @return [self]
      def collect_dice_bots
        dice_bots = [DiceBot.new] + DiceBotLoader.collectDiceBots
        dice_bot_ids = dice_bots.map(&:id)
        dice_bot_names = dice_bots.map(&:name)
        @dice_bot_wrappers = dice_bots.map { |bot| DiceBotWrapper.wrap(bot) }

        @id_to_dice_bot_wrapper_index = dice_bot_ids.each_with_index.to_h
        @name_to_dice_bot_wrapper_index = dice_bot_names.each_with_index.to_h

        self
      end

      # プリセット集を用意する
      # @return [self]
      def setup_preset_manager
        begin
          @preset_manager = PresetManager.load_yaml_file(@presets_yaml_path)
        rescue => e
          @logger.warn("プリセット集を読み込めません: #{e}")
        end

        if !@preset_manager || @preset_manager.empty?
          @preset_manager = PresetManager.default
          @logger.warn('既定のプリセット集を使用します')
        end

        self
      end

      # ウィジェット定義ファイルを読み込む
      # @return [self]
      def load_glade_file
        glade_file = File.expand_path('bcdice-irc.glade', __dir__)
        @builder.add_from_file(glade_file)
        @builder.connect_signals { |handler| method(handler) }

        self
      end

      # ウィジェットIDの配列
      WIDGET_IDS = [
        'main_window',

        'preset_combo_box',
        'preset_entry',

        'hostname_entry',
        'port_spin_button',
        'password_check_button',
        'password_entry',
        'nick_entry',
        'channel_entry',
        'connect_disconnect_button',

        'game_system_combo_box',
        'help_text_view',

        'bcdice_version_label',

        'status_bar',
      ].freeze

      # ウィジェットを用意する
      # @return [self]
      def setup_widgets
        # ウィジェットのインスタンス変数を用意する
        WIDGET_IDS.each do |id|
          instance_variable_set("@#{id}", @builder.get_object(id))
        end

        setup_status_bar_context_ids
        setup_version_labels
        setup_preset_combo_box
        setup_game_system_combo_box

        self
      end

      # ステータスバーに表示する項目の種類
      STATUS_BAR_CONTEXTS = [
        :preset_load,
        :game_system_change,
        :connection,
      ]

      # ステータスバーのコンテクストIDを用意する
      # @return [self]
      def setup_status_bar_context_ids
        @status_bar_context_ids = STATUS_BAR_CONTEXTS
                                  .map { |c| [c, @status_bar.get_context_id(c.to_s)] }
                                  .to_h

        self
      end

      # バージョン情報のラベルを用意する
      # @return [self]
      def setup_version_labels
        @bcdice_version_label.text =
          @bcdice_version_label.text % [BCDiceIRC::VERSION, BCDice::VERSION]

        self
      end

      # プリセットのコンボボックスを用意する
      # @return [self]
      def setup_preset_combo_box
        presets_store = Gtk::ListStore.new(Object, String)

        @preset_manager.each do |c|
          row = presets_store.append
          row[0] = c
          row[1] = c.name
        end

        @preset_combo_box.model = presets_store
        @preset_combo_box.entry_text_column = 1

        self
      end

      # ゲームシステムのコンボボックスを用意する
      # @return [self]
      def setup_game_system_combo_box
        game_system_list_store = Gtk::ListStore.new(Object, String)

        @dice_bot_wrappers.each do |w|
          row = game_system_list_store.append
          row[0] = w
          row[1] = w.name
        end

        @game_system_combo_box.model = game_system_list_store

        # 各行の描画について設定する
        game_system_cell_render = Gtk::CellRendererText.new
        @game_system_combo_box.pack_start(game_system_cell_render, true)
        @game_system_combo_box.add_attribute(game_system_cell_render, 'text', 1)

        self
      end

      # 最後に選択されていたプリセットを選択する
      # @return [self]
      # @todo 設定から読み込んで設定する
      def set_last_selected_preset
        # 無効なゲームシステムが設定されていた場合に備えて、
        # あらかじめ最初のゲームシステムを選んでおく
        @game_system_combo_box.active = 0

        @preset_combo_box.active = @preset_manager.index_last_selected

        self
      end

      # 状態に合わせてウィジェットを更新する
      # @return [self]
      def update_widgets
        @hostname_entry.sensitive = @state.hostname_entry_sensitive
        @port_spin_button.sensitive = @state.port_spin_button_sensitive

        @password_check_button.sensitive = @state.password_check_button_sensitive
        # パスワードの入力可否を更新するために再代入する
        self.use_password = @use_password

        @nick_entry.sensitive = @state.nick_entry_sensitive
        @channel_entry.sensitive = @state.channel_entry_sensitive

        @game_system_combo_box.sensitive = @state.game_system_combo_box_sensitive

        @connect_disconnect_button.label = @state.connect_disconnect_button_label
        @connect_disconnect_button.sensitive = @state.connect_disconnect_button_sensitive

        update_connection_status if @irc_bot_config

        self
      end

      # メインウィンドウが閉じられたときの処理
      # @return [void]
      def main_window_on_destroy
        @logger.debug('Stop mediator')
        @mediator.quit!
        @logger.debug('Mediator has stopped')

        Gtk.main_quit
      end

      # プリセットコンボボックスの値が変更されたときの処理
      def preset_combo_box_on_changed
        active_index = @preset_combo_box.active
        if active_index < 0
          # 文字が入力された場合
          # TODO: プリセット名のバリデーションを行い、保存できるかを判定する
        else
          # プリセットが選択された場合
          set_irc_bot_config_from_preset(@preset_combo_box.active_iter[0])
          @preset_manager.index_last_selected = active_index
        end
      end

      # ホスト名欄が変更されたときの処理
      # @return [void]
      def hostname_entry_on_changed
        @irc_bot_config.hostname = @hostname_entry.text
      end

      # ポートの値が変更されたときの処理
      # @return [void]
      def port_spin_button_on_value_changed
        @irc_bot_config.port = @port_spin_button.value.to_i
      end

      # パスワードチェックボタンが切り替えられたときの処理
      # @return [void]
      def password_check_button_on_toggled
        self.use_password = @password_check_button.active?
      end

      # パスワード欄が変更されたときの処理
      # @return [void]
      def password_entry_on_changed
        if @use_password
          @irc_bot_config.password = @password_entry.text
        end
      end

      # ニックネーム欄が変更されたときの処理
      # @return [void]
      def nick_entry_on_changed
        @irc_bot_config.nick = @nick_entry.text
      end

      # チャンネル欄が変更されたときの処理
      # @return [void]
      def channel_entry_on_changed
        @irc_bot_config.channel = @channel_entry.text
      end

      # ゲームシステムコンボボックスの値が変更されたときの処理
      # @return [void]
      def game_system_combo_box_on_changed
        self.dice_bot_wrapper = @game_system_combo_box.active_iter[0]
      end

      # 接続/切断ボタンがクリックされたときの処理
      # @return [self]
      def connect_disconnect_button_on_clicked
        @state.connect_disconnect_button_on_clicked
        self
      end
    end
  end
end
