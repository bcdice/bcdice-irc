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
require_relative 'combo_box'

require_relative 'signal_handlers'
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
      attr_reader :irc_bot_config
      # プリセット集
      # @return [PresetStore]
      attr_reader :preset_store
      # IRCボットとGUIとの仲介
      # @return [GUI::Mediator]
      attr_reader :mediator
      # ロガー
      # @return [CategorizableLogger]
      attr_reader :logger

      # 最後に発生した接続エラー
      # @return [StandardError, nil]
      attr_accessor :last_connection_error

      # 起動時の準備中か
      # @return [Boolean]
      attr_reader :setting_up

      # @!attribute [r] state
      #   @return [State::Base] アプリケーションの状態
      def_accessor_for_observable 'state', private_writer: true

      # @!attribute [rw] use_password
      #   @return [Boolean] パスワードを使用するか
      def_accessor_for_observable 'use_password'

      # @!attribute [r] dice_bot_wrapper
      #   @return [DiceBotWrapper] ダイスボットラッパ
      def_accessor_for_observable 'dice_bot_wrapper'

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
        @preset_store = PresetStore.new
        @irc_bot_config = IRCBot::Config::DEFAULT.deep_dup
        @setting_up = true
        @last_connection_error = nil

        @states = {
          disconnected: State::Disconnected.new(self),
          connecting: State::Connecting.new(self),
          connected: State::Connected.new(self),
          disconnecting: State::Disconnecting.new(self),
        }
        @state = SimpleObservable.new

        @logger = CategorizableLogger.new('Application', $stderr, level: @log_level)
        @preset_store.logger = @logger

        @mediator = Mediator.new(self, @log_level)
      end

      # アプリケーションを実行する
      # @return [self]
      def start!
        @setting_up = true
        @logger.debug('Setup start')

        collect_dice_bots
        load_presets

        load_glade_file
        setup_widgets
        setup_observers
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
        @last_connection_error = e
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

      # プリセットを削除するか確認するダイアログを表示する
      # @param [String] preset_name プリセット名
      # @return [:ok] OKボタンが押された場合
      # @return [:cancel] キャンセルボタンが押された場合
      def show_confirm_deleting_preset_dialog(preset_name)
        dialog = Gtk::MessageDialog.new(
          parent: @main_window,
          flags: :destroy_with_parent,
          type: :warning,
          buttons: :ok_cancel,
          message: "プリセット「#{preset_name}」を本当に削除しますか?"
        )
        dialog.secondary_text = 'この操作は元に戻せません。'

        response = dialog.run
        dialog.destroy

        response
      end

      # プリセット設定ファイルの保存を試みる
      # @return [true] 保存に成功した場合
      # @return [false] 保存に失敗した場合
      def try_to_save_presets_file
        save_presets_file
        true
      rescue => e
        @status_bar&.push(
          @status_bar_context_ids.fetch(:save_presets),
          'プリセット設定ファイルの保存に失敗しました'
        )
        @logger.exception(e)

        false
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

      # プリセット集を読み込む
      # @return [self]
      def load_presets
        begin
          @preset_store.load_yaml_file(@presets_yaml_path)
        rescue => e
          @logger.warn("プリセット集を読み込めません: #{e}")
        end

        if !@preset_store || @preset_store.empty?
          @preset_store = PresetStore.default
          @logger.warn('既定のプリセット集を使用します')
          try_to_save_presets_file
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

      # ビルダーからウィジェットを取得する
      # @param [String] object_id オブジェクトID
      # @return [Gtk::Widget]
      def w(object_id)
        widget = @builder.get_object(object_id)
        raise "widget #{object_id.inspect} not found" unless widget

        widget
      end

      # ウィジェットを用意する
      # @return [self]
      def setup_widgets
        @main_window = w('main_window')

        @preset_combo_box = w('preset_combo_box')
        @preset_entry = w('preset_entry')
        @preset_save_button = w('preset_save_button')
        @preset_delete_button = w('preset_delete_button')

        @hostname_entry = w('hostname_entry')
        @port_spin_button = w('port_spin_button')
        @password_check_button = w('password_check_button')
        @password_entry = w('password_entry')
        @encoding_combo_box = w('encoding_combo_box')
        @nick_entry = w('nick_entry')
        @channel_entry = w('channel_entry')
        @connect_disconnect_button = w('connect_disconnect_button')

        @game_system_combo_box = w('game_system_combo_box')
        @help_text_view = w('help_text_view')

        @bcdice_version_label = w('bcdice_version_label')

        @status_bar = w('status_bar')

        setup_status_bar_context_ids
        connect_signals
        setup_version_labels
        setup_encoding_combo_box
        setup_preset_combo_box
        setup_game_system_combo_box

        self
      end

      # シグナルにハンドラを割り当てる
      # @return [self]
      def connect_signals
        ids = @handler_ids
        h = SignalHandlers

        ids[:main_window_on_destroy] = @main_window.signal_connect(
          :destroy, &h.main_window_on_destroy(self)
        )

        ids[:preset_combo_box_on_changed] = @preset_combo_box.signal_connect(
          :changed, &h.preset_combo_box_on_changed(self)
        )
        ids[:preset_save_button_on_clicked] = @preset_save_button.signal_connect(
          :clicked,
          &h.preset_save_button_on_clicked(
            self,
            @preset_entry,
            @status_bar,
            @status_bar_context_ids.fetch(:save_presets)
          )
        )
        ids[:preset_delete_button_on_clicked] = @preset_delete_button.signal_connect(
          :clicked,
          &h.preset_delete_button_on_clicked(
            self,
            @preset_entry,
            @status_bar,
            @status_bar_context_ids.fetch(:save_presets)
          )
        )

        ids[:hostname_entry_on_changed] = @hostname_entry.signal_connect(
          :changed, &h.hostname_entry_on_changed(@irc_bot_config)
        )
        ids[:port_spin_button_on_value_changed] = @port_spin_button.signal_connect(
          :value_changed, &h.port_spin_button_on_value_changed(@irc_bot_config)
        )
        ids[:password_check_button_on_toggled] = @password_check_button.signal_connect(
          :toggled, &h.password_check_button_on_toggled(self)
        )
        ids[:password_entry_on_changed] = @password_entry.signal_connect(
          :changed, &h.password_entry_on_changed(self)
        )
        ids[:encoding_combo_box_on_changed] = @encoding_combo_box.signal_connect(
          :changed, &h.encoding_combo_box_on_changed(@irc_bot_config)
        )
        ids[:nick_entry_on_changed] = @nick_entry.signal_connect(
          :changed, &h.nick_entry_on_changed(@irc_bot_config)
        )
        ids[:channel_entry_on_changed] = @channel_entry.signal_connect(
          :changed, &h.channel_entry_on_changed(@irc_bot_config)
        )

        ids[:game_system_combo_box_on_changed] = @game_system_combo_box.signal_connect(
          :changed, &h.game_system_combo_box_on_changed(self)
        )

        ids[:connect_disconnect_button_on_clicked] = @connect_disconnect_button.signal_connect(
          :clicked, &h.connect_disconnect_button_on_clicked(self)
        )
      end

      # ステータスバーに表示する項目の種類
      STATUS_BAR_CONTEXTS = [
        :preset_load,
        :save_presets,
        :game_system_change,
        :connection,
      ].freeze

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
        @bcdice_version_label.text %= [BCDiceIRC::VERSION, BCDice::VERSION]
        self
      end

      # 文字コードコンボボックスを用意する
      # @return [self]
      def setup_encoding_combo_box
        ComboBox::Setup.bind(@encoding_combo_box, IRCBot::AVAILABLE_ENCODINGS)
        ComboBox::Setup.pack_cell_renderer_text(@encoding_combo_box)

        @encoding_combo_box_activator = ComboBox::Activator.new(
          @encoding_combo_box,
          IRCBot::AVAILABLE_ENCODINGS.map(&:name)
        )

        self
      end

      # プリセットのコンボボックスを用意する
      # @return [self]
      def setup_preset_combo_box
        @preset_store.map(&:name)
                     .each do |preset_name|
                       @preset_combo_box.append_text(preset_name)
                     end

        self
      end

      # ゲームシステムのコンボボックスを用意する
      # @return [self]
      def setup_game_system_combo_box
        ComboBox::Setup.bind(@game_system_combo_box, @dice_bot_wrappers, &:name)
        ComboBox::Setup.pack_cell_renderer_text(@game_system_combo_box)

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

        setup_preset_load_observers
        setup_preset_save_observers
        setup_preset_delete_observers

        @preset_store.add_preset_save_action_updated_handlers(
          Observers::PresetSaveAction.preset_save_button(@preset_save_button)
        )

        @preset_store.add_preset_deletability_updated_handlers(
          Observers::PresetDeletability.preset_delete_button(@preset_delete_button)
        )

        setup_password_usage_observers
        setup_dice_bot_wrapper_observers
      end

      # アプリケーションの状態のオブザーバを用意する
      # @return [self]
      def setup_state_observers
        widgets = [
          @preset_combo_box,
          @preset_save_button,
          @preset_delete_button,

          @hostname_entry,
          @port_spin_button,
          @encoding_combo_box,
          @nick_entry,
          @channel_entry,

          @game_system_combo_box,
        ]

        @state.add_observers(
          Observers::State.main_window_title(self),
          Observers::State.general_widgets(widgets),
          Observers::State.widgets_for_password(@password_check_button, self),
          Observers::State.connect_disconnect_button(@connect_disconnect_button),
          Observers::State.logger(@logger),
          Observers::State.status_bar(
            self,
            @status_bar,
            @status_bar_context_ids.fetch(:connection)
          )
        )

        self
      end

      # プリセット読み込みのオブザーバを用意する
      # @return [self]
      def setup_preset_load_observers
        @preset_store.add_preset_load_handlers(
          Observers::PresetLoad.hostname_entry(@hostname_entry),
          Observers::PresetLoad.port_spin_button(@port_spin_button),
          Observers::PresetLoad.widgets_for_password(@password_check_button, @password_entry),
          Observers::PresetLoad.nick_entry(@nick_entry),
          Observers::PresetLoad.channel_entry(@channel_entry),
          Observers::PresetLoad.encoding_combo_box(@encoding_combo_box_activator),
          Observers::PresetLoad.game_system_combo_box(@game_system_combo_box_activator_id),
          Observers::PresetLoad.irc_bot_config(@irc_bot_config),
          Observers::PresetLoad.status_bar(
            @status_bar,
            @status_bar_context_ids.fetch(:preset_load)
          )
        )

        self
      end

      # プリセット追加/更新のオブザーバを用意する
      # @return [self]
      def setup_preset_save_observers
        preset_combo_box_active_observer = Observers::PresetSave.preset_combo_box_active(
          @preset_combo_box,
          @handler_ids.fetch(:preset_combo_box_on_changed)
        )

        @preset_store.add_preset_append_handlers(
          Observers::PresetSave.preset_combo_box_append_item(@preset_combo_box),
          preset_combo_box_active_observer
        )

        @preset_store.add_preset_update_handlers(
          preset_combo_box_active_observer
        )

        self
      end

      # プリセット削除のオブザーバを用意する
      # @return [self]
      def setup_preset_delete_observers
        @preset_store.add_preset_delete_handlers(
          Observers::PresetDelete.preset_combo_box_remove_item(@preset_combo_box),
          Observers::PresetDelete.preset_entry_clear(@preset_entry)
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
      def set_last_selected_preset
        # コンボボックス：無効な値が設定されていた場合に備えて、
        # あらかじめ最初の項目を選んでおく
        @encoding_combo_box.active = 0
        @game_system_combo_box.active = 0

        # activeが必ず0以上になるようにする
        @preset_combo_box.active =
          [0, @preset_store.index_last_selected].max

        self
      end

      # プリセット設定ファイルを保存する
      # @return [self]
      def save_presets_file
        @preset_store.write_yaml_file(@presets_yaml_path)
        @logger.debug("#{@presets_yaml_path}: 保存しました")

        self
      end
    end
  end
end
