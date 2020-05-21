# frozen_string_literal: true

module BCDiceIRC
  module GUI
    # GTKのシグナルハンドラを格納するモジュール
    module SignalHandlers
      module_function

      # メインウィンドウが閉じられたときの処理
      # @param [Application] app
      # @return [Proc]
      def main_window_on_destroy(app)
        lambda do |_|
          app.logger.debug('Stop mediator')
          app.mediator.quit!
          app.logger.debug('Mediator has stopped')

          Gtk.main_quit
        end
      end

      # プリセットコンボボックスの値が変更されたときの処理
      # @param [Application] app
      # @return [Proc]
      def preset_combo_box_on_changed(app)
        lambda do |combo_box|
          active_index = combo_box.active
          if active_index < 0
            # 文字が入力された場合
            app.preset_store_vm.temporary_preset_name = combo_box.active_text
          else
            # プリセットが選択された場合
            app.preset_store_vm.load_by_index(active_index)

            app.try_to_save_presets_file unless app.setting_up
          end
        end
      end

      # プリセット保存ボタンがクリックされたときの処理
      # @param [Application] app
      # @param [Gtk::Entry] preset_entry
      # @param [Gtk::StatusBar] status_bar
      # @param [Integer] context_id
      # @return [Proc]
      def preset_save_button_on_clicked(app, preset_entry, status_bar, context_id)
        lambda do |_|
          app.irc_bot_config.name = preset_entry.text

          result = app.preset_store_vm.save(app.irc_bot_config.deep_dup)

          if app.try_to_save_presets_file
            action = result.action == :appended ? '保存' : '更新'
            status_bar.push(
              context_id,
              "プリセット「#{result.config.name}」を#{action}しました"
            )
          end
        end
      end

      # プリセット削除ボタンがクリックされたときの処理
      # @param [Application] app
      # @param [Gtk::Entry] preset_entry
      # @param [Gtk::StatusBar] status_bar
      # @param [Integer] context_id
      # @return [Proc]
      def preset_delete_button_on_clicked(app, preset_entry, status_bar, context_id)
        lambda do |_|
          preset_name = preset_entry.text

          response = app.show_confirm_deleting_preset_dialog(preset_name)
          return unless response == :ok

          result = app.preset_store_vm.delete(preset_name)
          return unless result.deleted

          if app.try_to_save_presets_file
            status_bar.push(context_id, "プリセット「#{result.config.name}」を削除しました")
          end
        end
      end

      # ホスト名欄が変更されたときの処理
      # @param [IRCBotConfig] config
      # @return [Proc]
      def hostname_entry_on_changed(config)
        ->(entry) { config.hostname = entry.text }
      end

      # ポートの値が変更されたときの処理
      # @param [IRCBotConfig] config
      # @return [Proc]
      def port_spin_button_on_value_changed(config)
        ->(spin_button) { config.port = spin_button.value.to_i }
      end

      # パスワードチェックボタンが切り替えられたときの処理
      # @param [Application] app
      # @return [Proc]
      def password_check_button_on_toggled(app)
        ->(check_button) { app.use_password = check_button.active? }
      end

      # パスワード欄が変更されたときの処理
      # @param [Application] app
      # @return [Proc]
      def password_entry_on_changed(app)
        ->(entry) { app.irc_bot_config.password = entry.text if app.use_password }
      end

      # 文字コードコンボボックスの値が変更されたときの処理
      # @param [IRCBotConfig] config
      # @return [Proc]
      def encoding_combo_box_on_changed(config)
        ->(combo_box) { config.encoding = combo_box.active_iter[0] }
      end

      # ニックネーム欄が変更されたときの処理
      # @param [IRCBotConfig] config
      # @return [Proc]
      def nick_entry_on_changed(config)
        ->(entry) { config.nick = entry.text }
      end

      # チャンネル欄が変更されたときの処理
      # @param [IRCBotConfig] config
      # @return [Proc]
      def channel_entry_on_changed(config)
        ->(entry) { config.channel = entry.text }
      end

      # ゲームシステムコンボボックスの値が変更されたときの処理
      # @param [Application] app
      # @return [Proc]
      def game_system_combo_box_on_changed(app)
        ->(combo_box) { app.dice_bot_wrapper = combo_box.active_iter[0] }
      end

      # 接続/切断ボタンがクリックされたときの処理
      # @param [Application] app
      # @return [Proc]
      def connect_disconnect_button_on_clicked(app)
        ->(_) { app.state.connect_disconnect_button_on_clicked }
      end
    end
  end
end
