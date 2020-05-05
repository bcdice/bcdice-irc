# frozen_string_literal: true

module BCDiceIRC
  class IRCBot
    PluginConfig = Struct.new(
      :bcdice,
      :mediator,
      keyword_init: true
    )
  end
end
