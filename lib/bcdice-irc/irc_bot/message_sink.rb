# frozen_string_literal: true

module BCDiceIRC
  class IRCBot
    class MessageSink
      # 初期化する
      # @param [Cinch::Bot] bot Cinchボット
      # @param [Cinch::User] sender メッセージの送信者
      def initialize(bot, sender)
        @bot = bot
        @sender = sender
      end

      # IRCボットを終了させる処理（何もしない）
      def quit; end

      # 指定したチャンネルにメッセージを送信する
      #
      # BCDiceとインターフェースを合わせるためのメソッド。
      #
      # @param [String] channel チャンネル
      # @param [String] message 送信するメッセージ
      # @return [void]
      # @todo プロット機能がチャンネルを指定するため、一時的にそれに合わせる。
      #   いずれIRCボットがすべて管理するようにするため、不要になる予定。
      def sendMessage(channel, message)
        target = Cinch::Target.new(channel, @bot)
        target.notice(message)
      end

      # メッセージの送信者に返信する
      #
      # @param [String] _nick 送信者のニックネーム（使用しない）
      # @param [String] message 返信するメッセージ
      # @return [void]
      def sendMessageToOnlySender(_nick, message)
        @sender.notice(message)
      end

      # 全チャンネルにメッセージを送信する
      # @param [String] message 送信するメッセージ
      # @return [void]
      def sendMessageToChannels(message)
        @bot.channels.each do |channel|
          channel.notice(message)
        end
      end
    end
  end
end
