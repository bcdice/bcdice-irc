# frozen_string_literal: true

require 'cinch'

require 'bcdiceCore'

module BCDiceIRC
  module IRCBotPlugin
    # IRCチャンネル関連の処理を担うプラグイン
    class IRCChannel
      include Cinch::Plugin

      self.plugin_name = 'IRCChannel'
      self.prefix = ''

      listen_to(:join, method: :on_join)
      listen_to(:invite, method: :on_invite)
      listen_to(:kick, method: :on_kick)

      private

      # JOINしたときの処理
      # @return [void]
      def on_join(m)
        if m.user == bot
          warn("#{m.channel} に参加しました")
        end
      end

      # INVITEされたときの処理
      # @return [void]
      def on_invite(m)
        warn("#{m.user} から #{m.channel} に招待されました")
        m.channel.join
      end

      # KICKされたときの処理
      # @return [void]
      def on_kick(m)
        target = User(m.params[1])
        if target == bot
          warn("#{m.user} によって #{m.channel} から追い出されました")
        end
      end
    end
  end
end
