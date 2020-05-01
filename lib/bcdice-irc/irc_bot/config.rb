# frozen_string_literal: true

module BCDiceIRC
  class IRCBot
    Config = Struct.new(
      :hostname,
      :port,
      :password,
      :nick,
      :channel,
      keyword_init: true
    )
  end
end
