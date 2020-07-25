# frozen_string_literal: true

require 'cinch'

require 'bcdiceCore'

require_relative 'utils'

module BCDiceIRC
  module IRCBotPlugin
    # カード関連コマンドを実行するプラグイン
    class CardCommand
      include Cinch::Plugin
      include Utils

      self.plugin_name = 'CardCommand'
      self.prefix = ''

      match(/\Ac-vhand (#{NICK_RE})/io, react_on: :channel, method: :show_users_hands)

      # プラグインを初期化する
      def initialize(*)
        super

        @bcdice = config.bcdice
      end

      private

      def show_users_hands(m, nick)
        hands = @bcdice.cardTrader.getHandAndPlaceCardInfoText('c-hand', nick)
        m.user.notice("#{nick} の手札は #{hands} です")
      end
    end
  end
end
