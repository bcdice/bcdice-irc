# frozen_string_literal: true

module BCDiceIRC
  module IRCBotPlugin
    # IRCボットプラグイン用のユーティリティメソッドを格納するモジュール
    module Utils
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
