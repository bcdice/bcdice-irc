# frozen_string_literal: true

module BCDiceIRC
  class IRCBot
    PluginConfig = Struct.new(
      :bcdice,
      keyword_init: true
    )
  end
end
