# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module Observers
      # アプリケーションの状態のオブザーバを格納するモジュール
      module State
        module_function

        # メインウィンドウのタイトルのオブザーバを返す
        # @param [Application] app
        # @return [Proc]
        def main_window_title(app)
          lambda do |_|
            app.update_main_window_title
          end
        end

        # IRCボット設定の一般的なウィジェットのオブザーバを返す
        # @param [WidgetSet] widget_set ウィジェット集
        # @return [Proc]
        def general_widgets(widget_set)
          widgets = [
            widget_set.preset_combo_box,
            widget_set.preset_save_button,
            widget_set.preset_delete_button,

            widget_set.hostname_entry,
            widget_set.port_spin_button,
            widget_set.encoding_combo_box,
            widget_set.nick_entry,
            widget_set.channel_entry,

            widget_set.game_system_combo_box,
          ]

          lambda do |state|
            widgets.each do |w|
              w.sensitive = state.general_widgets_sensitive
            end
          end
        end

        # パスワード設定用ウィジェットのオブザーバを返す
        # @param [Gtk::CheckButton] password_check_button
        # @param [Application] app
        # @return [Proc]
        def widgets_for_password(password_check_button, app)
          lambda do |state|
            password_check_button.sensitive = state.general_widgets_sensitive
            app.update_widgets_for_password
          end
        end

        # 接続/切断ボタンのオブザーバを返す
        # @param [Gtk::Button] button
        # @return [Proc]
        def connect_disconnect_button(button)
          lambda do |state|
            button.label = state.connect_disconnect_button_label
            button.sensitive = state.connect_disconnect_button_sensitive
          end
        end

        # ステータスバーのオブザーバを返す
        # @param [Application] app
        # @param [Gtk::StatusBar] bar
        # @param [Integer] context_id
        # @return [Proc]
        def status_bar(app, bar, context_id)
          lambda do |state|
            unless app.setting_up
              bar.push(
                context_id,
                state.connection_status
              )
            end
          end
        end

        # ロガーのオブザーバを返す
        # @param [Cinch::Logger] l
        # @return [Proc]
        def logger(l)
          lambda do |state|
            l.info("State -> #{state.name}")
          end
        end
      end
    end
  end
end
