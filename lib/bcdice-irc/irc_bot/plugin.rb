# frozen_string_literal: true

module BCDiceIRC
  class IRCBot
    # Cinchボットのプラグインを格納するモジュール
    module Plugin; end
  end
end

require_relative 'plugin/irc_channel'
require_relative 'plugin/dice_command'
require_relative 'plugin/master_command'
