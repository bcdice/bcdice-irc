# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module Observers
      # プリセット読み込みのオブザーバを格納するモジュール
      module PresetLoad
        module_function

        # ホスト名エントリのオブザーバを返す
        # @param [Gtk::Entry] entry
        # @return [Proc]
        def hostname_entry(entry)
          lambda do |config, _index|
            entry.text = config.hostname
          end
        end

        # ポート番号スピンボタンのオブザーバを返す
        # @param [Gtk::SpinButton] spin_button
        # @return [Proc]
        def port_spin_button(spin_button)
          lambda do |config, _index|
            spin_button.value = config.port
          end
        end

        # パスワード設定用ウィジェットのオブザーバを返す
        # @param [Gtk::CheckButton] password_check_button
        # @param [Gtk::Entry] password_entry
        # @return [Proc]
        def widgets_for_password(password_check_button, password_entry)
          lambda do |config, _index|
            if config.password
              password_check_button.active = true
              password_entry.text = config.password
            else
              password_check_button.active = false
              password_entry.text = ''
            end
          end
        end

        # ニックネームエントリのオブザーバを返す
        # @param [Gtk::Entry] entry
        # @return [Proc]
        def nick_entry(entry)
          lambda do |config, _index|
            entry.text = config.nick
          end
        end

        # チャンネルエントリのオブザーバを返す
        # @param [Gtk::Entry] entry
        # @return [Proc]
        def channel_entry(entry)
          lambda do |config, _index|
            entry.text = config.channel
          end
        end

        # 文字コードコンボボックスのオブザーバを返す
        # @param [ComboBox::Activator] activator
        # @return [Proc]
        def encoding_combo_box(activator)
          lambda do |config, _index|
            activator.activate(config.encoding.name)
          end
        end

        # ゲームシステムコンボボックスのオブザーバを返す
        # @param [ComboBox::Activator] activator
        # @return [Proc]
        def game_system_combo_box(activator)
          lambda do |config, _index|
            activator.activate(config.game_system_id)
          end
        end

        # IRCボット設定のオブザーバを返す
        # @param [IRCBotConfig] config_in_app
        # @return [Proc]
        def irc_bot_config(config_in_app)
          lambda do |preset, _index|
            config_in_app.quit_message = preset.quit_message.dup
          end
        end

        # ステータスバーのオブザーバを返す
        # @param [Gtk::StatusBar] bar
        # @param [Integer] context_id
        # @return [Proc]
        def status_bar(bar, context_id)
          lambda do |config, _index|
            bar.push(context_id, "プリセット「#{config.name}」を読み込みました")
          end
        end
      end
    end
  end
end
