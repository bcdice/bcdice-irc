# frozen_string_literal: true

module BCDiceIRC
  module GUI
    # アプリケーションの状態のオブザーバを格納するモジュール
    module StateObserver
      module_function

      def main_window_title(app)
        lambda do |_|
          app.update_main_window_title
        end
      end

      def general_widgets(widgets)
        lambda do |state|
          widgets.each do |w|
            w.sensitive = state.general_widgets_sensitive
          end
        end
      end

      def widgets_for_password(password_check_button, app)
        lambda do |state|
          password_check_button.sensitive = state.general_widgets_sensitive
          # パスワードの入力可否を更新するために再代入する
          app.use_password = @use_password
        end
      end

      def connect_disconnect_button(button)
        lambda do |state|
          button.label = state.connect_disconnect_button_label
          button.sensitive = state.connect_disconnect_button_sensitive
        end
      end

      def status_bar(bar, context_id)
        lambda do |state|
          bar.push(
            context_id,
            state.connection_status
          )
        end
      end

      def logger(l)
        lambda do |state|
          l.info("State -> #{state.name}")
        end
      end
    end
  end
end
