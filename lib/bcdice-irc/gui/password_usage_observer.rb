# frozen_string_literal: true

module BCDiceIRC
  module GUI
    # パスワードの使用についてのオブザーバを格納するモジュール
    module PasswordUsageObserver
      module_function

      def irc_bot_config(config, password_entry)
        lambda do |use_password|
          config.password = use_password ? password_entry.text : nil
        end
      end

      def password_entry(entry, app)
        lambda do |use_password|
          entry.sensitive =
            app.state.general_widgets_sensitive && use_password
        end
      end
    end
  end
end
