# frozen_string_literal: true

# BCDiceIRCの機能を格納するモジュール
module BCDiceIRC; end

require_relative 'bcdice-irc/version'
require_relative 'bcdice-irc/categorizable_logger'
require_relative 'bcdice-irc/dice_bot_wrapper'
require_relative 'bcdice-irc/encoding_info'
require_relative 'bcdice-irc/irc_bot_config'
require_relative 'bcdice-irc/irc_bot'
require_relative 'bcdice-irc/irc_message_sink'
require_relative 'bcdice-irc/irc_bot_plugin_config'
require_relative 'bcdice-irc/irc_bot_plugin'
