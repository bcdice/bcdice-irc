# frozen_string_literal: true

module BCDiceIRC
  # Cinchプラグインの設定の構造体
  # @!attribute bcdice
  #   @return [BCDice] BCDice
  # @!attribute mediator
  #   @return [GUI::Mediator] IRCボットとGUIとの仲介
  IRCBotPluginConfig = Struct.new(
    :bcdice,
    :mediator,
    keyword_init: true
  )
end
