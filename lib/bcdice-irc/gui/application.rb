# frozen_string_literal: true

require 'forwardable'

require 'gtk3'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/object/blank'

require 'bcdiceCore'
require 'diceBot/DiceBot'
require 'diceBot/DiceBotLoader'

require_relative '../version'
require_relative '../dice_bot_wrapper'
require_relative '../irc_bot'
require_relative '../categorizable_logger'

require_relative 'mediator'
require_relative 'state'
require_relative 'preset_store'
require_relative 'preset_save_state'
require_relative 'combo_box'

require_relative 'simple_observable'
require_relative 'forwardable_to_observer'
require_relative 'observers'

module BCDiceIRC
  module GUI
    # BCDice IRCのGUIアプリケーションのクラス
    class Application
      extend ForwardableToObserver

      # IRCボットの設定
      # @return [IRCBot::Config]
      attr_accessor :irc_bot_config
      # IRCボットとGUIとの仲介
      # @return [GUI::Mediator]
      attr_reader :mediator

      # 最後に発生した接続エラー
      # @return [StandardError, nil]
      attr_accessor :last_connection_exception

      # @!attribute [r] state
      #   @return [State::Base] アプリケーションの状態
      def_accessor_for_observable 'state', private_writer: true

      # プリセットの保存に関する状態
      def_accessor_for_observable(
        'preset_save_state',
        private_reader: true,
        private_writer: true
      )

      # パスワードを使用するか
      def_accessor_for_observable(
        'use_password',
        private_reader: true,
        private_writer: true
      )

      # @!attribute [r] dice_bot_wrapper
      #   @return [DiceBotWrapper] ダイスボットラッパ
      def_accessor_for_observable 'dice_bot_wrapper', private_writer: true

      # アプリケーションを初期化する
      # @param [String] presets_yaml_path プリセット集のYAMLファイルのパス
      # @param [Symbol] log_level ログレベル
      def initialize(presets_yaml_path, log_level)
        @presets_yaml_path = presets_yaml_path
        @log_level = log_level

        @builder = Gtk::Builder.new
        @handler_ids = {}

        @use_password = SimpleObservable.new
        @dice_bot_wrapper = SimpleObservable.new
        @preset_store = nil
        @irc_bot_config = IRCBot::Config::DEFAULT.deep_dup
        @last_connection_exception = nil

        @states = {
          disconnected: State::Disconnected.new(self),
          connecting: State::Connecting.new(self),
          connected: State::Connected.new(self),
          disconnecting: State::Disconnecting.new(self),
        }
        @state = SimpleObservable.new

        @preset_save_state = SimpleObservable.new

        @logger = CategorizableLogger.new('Application', $stderr, level: @log_level)
        @mediator = Mediator.new(self, @log_level)
      end

      # アプリケーションを実行する
      # @return [self]
      def start!
        @logger.debug('Setup start')

        collect_dice_bots
        setup_preset_store

        load_glade_file
        setup_widgets
        setup_observers
        change_state(:disconnected)
        set_last_selected_preset

        # ウィジェットの準備が終わったので、アプリケーションの状態に対する
        # ステータスバーのオブザーバを追加する
        @state.add_observer(
          Observers::State.status_bar(
            @status_bar,
            @status_bar_context_ids.fetch(:connection)
          )
        )

        @main_window.show_all

        @logger.debug('Setup end')

        @logger.debug('Start mediator')
        @mediator.start!

        @logger.debug('Main loop start')
        Gtk.main
        @logger.debug('Main loop end')

        self
      end

      # ゲームシステムを名前で指定して変更する
      #
      # ゲームシステム名に対応するダイスボットラッパが設定される。
      # 対応するダイスボットラッパが見つからなかった場合には何もしない。
      #
      # @param [String] value 新しいゲームシステム名
      # @note ウィジェットの準備が完了してから使うこと。
      def game_system_name=(value)
        @game_system_combo_box_activator_name.activate(value)
      end

      # アプリケーションの状態を変更する
      # @param [Symbol] id 状態のID
      # @return [self]
      def change_state(id)
        self.state = @states.fetch(id)
        self
      end

      # プリセットからIRCボット設定を設定する
      # @param [IRCBot::Config] preset_name プリセット名
      # @return [self]
      def set_irc_bot_config_by_preset_name(preset_name)
        irc_bot_config = @preset_store.fetch_by_name(preset_name)

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
        @encoding_combo_box_activator.activate(irc_bot_config.encoding.name)
        @game_system_combo_box_activator_id.activate(irc_bot_config.game_system_id)

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
        @main_window.title = "#{state.main_window_title} - BCDice IRC"
        self
      end

      # パスワード関連のウィジェットを更新する
      # @return [self]
      # @note ウィジェットの準備が完了してから使うこと。
      def update_widgets_for_password
        @use_password.notify_observers
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

      # ダイスボットを収集し、キャッシュする
      # @return [self]
      def collect_dice_bots
        @dice_bots = [DiceBot.new] + DiceBotLoader.collectDiceBots
        @dice_bot_wrappers = @dice_bots.map { |bot| DiceBotWrapper.wrap(bot) }

        self
      end

      # プリセット集を用意する
      # @return [self]
      def setup_preset_store
        @preset_store = PresetStore.new
        @preset_store.logger = @logger

        begin
          @preset_store.load_yaml_file(@presets_yaml_path)
        rescue => e
          @logger.warn("プリセット集を読み込めません: #{e}")
        end

        if !@preset_store || @preset_store.empty?
          @preset_store = PresetStore.default
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
        'preset_save_button',
        'preset_delete_button',

        'hostname_entry',
        'port_spin_button',
        'password_check_button',
        'password_entry',
        'encoding_combo_box',
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
        setup_encoding_combo_box
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

      # 文字コードコンボボックスを用意する
      # @return [self]
      def setup_encoding_combo_box
        ComboBox::Setup.bind(@encoding_combo_box, IRCBot::AVAILABLE_ENCODINGS)
        ComboBox::Setup.set_cell_renderer_text(@encoding_combo_box)

        @encoding_combo_box_activator = ComboBox::Activator.new(
          @encoding_combo_box,
          IRCBot::AVAILABLE_ENCODINGS.map(&:name)
        )

        self
      end

      # プリセットのコンボボックスを用意する
      # @return [self]
      def setup_preset_combo_box
        @preset_store
          .map(&:name)
          .each do |preset_name|
            @preset_combo_box.append_text(preset_name)
          end

        @handler_ids[:preset_combo_box_on_changed] =
          @preset_combo_box.signal_connect(:changed) do
            preset_combo_box_on_changed
          end

        self
      end

      # ゲームシステムのコンボボックスを用意する
      # @return [self]
      def setup_game_system_combo_box
        ComboBox::Setup.bind(@game_system_combo_box, @dice_bot_wrappers, &:name)
        ComboBox::Setup.set_cell_renderer_text(@game_system_combo_box)

        @game_system_combo_box_activator_id = ComboBox::Activator.new(
          @game_system_combo_box,
          @dice_bots.map(&:id)
        )

        @game_system_combo_box_activator_name = ComboBox::Activator.new(
          @game_system_combo_box,
          @dice_bots.map(&:name)
        )

        self
      end

      # オブザーバを用意する
      # @return [self]
      def setup_observers
        setup_state_observers

        @preset_save_state.add_observer(
          Observers::PresetSaveState.preset_save_button(@preset_save_button)
        )

        setup_password_usage_observers
        setup_dice_bot_wrapper_observers
      end

      # アプリケーションの状態のオブザーバを用意する
      # @return [self]
      def setup_state_observers
        widgets = [
          @hostname_entry,
          @port_spin_button,
          @encoding_combo_box,
          @nick_entry,
          @channel_entry,

          @game_system_combo_box,
        ]

        # 初期状態を設定する前は、ステータスバーのオブザーバは追加しないこと
        # （起動していきなり「切断されました」と表示されないように）
        @state.add_observers(
          Observers::State.main_window_title(self),
          Observers::State.general_widgets(widgets),
          Observers::State.widgets_for_password(@password_check_button, self),
          Observers::State.connect_disconnect_button(@connect_disconnect_button),
          Observers::State.logger(@logger)
        )

        self
      end

      # パスワードの使用についてのオブザーバを用意する
      # @return [self]
      def setup_password_usage_observers
        @use_password.add_observers(
          Observers::PasswordUsage.irc_bot_config(@irc_bot_config, @password_entry),
          Observers::PasswordUsage.password_entry(@password_entry, self)
        )

        self
      end

      # ダイスボットラッパのオブザーバを用意する
      # @return [self]
      def setup_dice_bot_wrapper_observers
        @dice_bot_wrapper.add_observers(
          Observers::GameSystem.irc_bot_config(@irc_bot_config),
          Observers::GameSystem.help_text_view(@help_text_view),
          Observers::GameSystem.main_window_title(self),
          Observers::GameSystem.status_bar(
            self,
            @status_bar,
            @status_bar_context_ids.fetch(:game_system_change)
          )
        )

        self
      end

      # 最後に選択されていたプリセットを選択する
      # @return [self]
      # @todo 設定から読み込んで設定する
      def set_last_selected_preset
        # コンボボックス：無効な値が設定されていた場合に備えて、
        # あらかじめ最初の項目を選んでおく
        @encoding_combo_box.active = 0
        @game_system_combo_box.active = 0

        @preset_combo_box.active = @preset_store.index_last_selected

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
          self.preset_save_state = preset_save_state_by_name(@preset_entry.text)
        else
          # プリセットが選択された場合
          set_irc_bot_config_by_preset_name(@preset_combo_box.active_text)
          @preset_store.index_last_selected = active_index
          self.preset_save_state = PresetSaveState::PRESET_EXISTS
        end
      end

      # 入力されたプリセット名から、プリセットの保存に関する状態を求める
      # @param [String] name 入力されたプリセット名
      # @return [PresetSaveState]
      def preset_save_state_by_name(name)
        if @preset_store.include?(name)
          PresetSaveState::PRESET_EXISTS
        elsif name.blank?
          PresetSaveState::INVALID_NAME
        else
          PresetSaveState::NEW_PRESET
        end
      end

      # プリセット保存ボタンがクリックされたときの処理
      # @return [void]
      def preset_save_button_on_clicked
        @irc_bot_config.name = @preset_entry.text
        result = @preset_store.push(@irc_bot_config.deep_dup)
        @logger.info("Preset: #{result} #{@irc_bot_config.name.inspect}")

        case result
        when :appended
          @logger.warn("Preset: combo box update after appending not implemented")
        when :updated
          @logger.debug("Preset: combo box update after update")
          @preset_combo_box.active = @preset_store.index_last_selected
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
        if use_password
          @irc_bot_config.password = @password_entry.text
        end
      end

      # 文字コードコンボボックスの値が変更されたときの処理
      def encoding_combo_box_on_changed
        @irc_bot_config.encoding = @encoding_combo_box.active_iter[0]
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
        state.connect_disconnect_button_on_clicked
        self
      end
    end
  end
end
