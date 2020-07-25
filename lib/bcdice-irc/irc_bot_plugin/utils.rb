# frozen_string_literal: true

module BCDiceIRC
  module IRCBotPlugin
    # IRCボットプラグイン用のユーティリティメソッドを格納するモジュール
    module Utils
      # ニックネームとして指定可能な文字のパターン
      #
      # Charybdisを参考にした。
      #
      # 最初の文字は、数字および `'-'` 以外。
      #
      # @see https://github.com/charybdis-ircd/charybdis/blob/charybdis-4.1.2/ircd/client.c#L903-L933
      # @see https://github.com/charybdis-ircd/charybdis/blob/charybdis-4.1.2/include/match.h#L118
      # @see https://github.com/charybdis-ircd/charybdis/blob/charybdis-4.1.2/ircd/match.c#L659-L793
      NICK_RE = /[A-Z\[\\\]^_`a-z{|}][-0-9A-Z\[\\\]^_`a-z{|}]*/

      # ボットに直接送られたメッセージかを返す
      # @return [Boolean]
      def direct_message?(m)
        !m.channel && m.target == m.user
      end

      # チャンネルに送られたメッセージかを返す
      # @return [Boolean]
      def channel_message?(m)
        !m.channel.nil?
      end

      # メッセージの各行をNOTICEする
      # @param [Cinch::Target] target 送信対象
      # @param [String] message 送信するメッセージ
      # @return [self]
      def notice_each_line(target, message)
        message.each_line do |line|
          target.notice(line.chomp)
        end

        self
      end

      # 参加しているすべてのチャンネルにメッセージを送信する
      # @param [String] message 送信するメッセージ
      # @return [self]
      def broadcast(message)
        bot.channels.each do |channel|
          channel.notice(message)
        end

        self
      end
    end
  end
end
