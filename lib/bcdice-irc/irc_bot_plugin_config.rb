# frozen_string_literal: true

module BCDiceIRC
  # Cinchプラグインの設定の構造体
  # @!attribute bcdice
  #   @return [BCDice] BCDice
  # @!attribute mediator
  #   @return [GUI::Mediator] IRCボットとGUIとの仲介
  # @!attribute new_target_proc
  #   @return [Proc] IRCメッセージの送信対象オブジェクトを作る手続き
  IRCBotPluginConfig = Struct.new(
    :bcdice,
    :mediator,
    :new_target_proc,
    keyword_init: true
  )
end
