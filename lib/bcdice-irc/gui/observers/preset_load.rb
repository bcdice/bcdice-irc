# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module Observers
      # プリセット読み込みのオブザーバを格納するモジュール
      module PresetLoad
        module_function

        # 接続設定用ウィジェットのオブザーバを返す
        # @param [WidgetSet] w ウィジェット集
        # @return [Proc]
        def connection_settings_form(w)
          lambda do |config, _index|
            w.hostname_entry.text = config.hostname
            w.port_spin_button.value = config.port

            if config.password
              w.password_check_button.active = true
              w.password_entry.text = config.password
            else
              w.password_check_button.active = false
              w.password_entry.text = ''
            end

            w.nick_entry.text = config.nick
            w.channel_entry.text = config.channel
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
