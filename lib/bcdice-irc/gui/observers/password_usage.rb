# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module Observers
      # パスワードの使用についてのオブザーバを格納するモジュール
      module PasswordUsage
        module_function

        # IRCボット設定のオブザーバを返す
        # @param [IRCBot::Config] config
        # @return [Proc]
        def irc_bot_config(config, password_entry)
          lambda do |use_password|
            config.password = use_password ? password_entry.text : nil
          end
        end

        # パスワードエントリのオブザーバを返す
        # @param [Gtk::Entry] entry
        # @param [Application] app
        # @return [Proc]
        def password_entry(entry, app)
          lambda do |use_password|
            entry.sensitive =
              app.state.general_widgets_sensitive && use_password
          end
        end
      end
    end
  end
end
