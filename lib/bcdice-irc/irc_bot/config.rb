# frozen_string_literal: true

module BCDiceIRC
  class IRCBot
    Config = Struct.new(
      :hostname,
      :port,
      :password,
      :nick,
      :channel,
      :quit_message,
      :game_system_id,
      keyword_init: true
    )
  end
end
