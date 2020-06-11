# frozen_string_literal: true

module BCDiceIRC
  # Cinchボットのプラグインを格納するモジュール
  module IRCBotPlugin; end
end

require_relative 'irc_bot_plugin/utils'

require_relative 'irc_bot_plugin/irc_channel'
require_relative 'irc_bot_plugin/dice_command'
require_relative 'irc_bot_plugin/master_command'
require_relative 'irc_bot_plugin/help_command'
