# frozen_string_literal: true

module BCDiceIRC
  # BCDiceからのメッセージの送信先
  class IRCMessageSink
    # 既定のIRCメッセージの送信対象オブジェクトを作る手続き
    # @return [Proc]
    DEFAULT_NEW_TARGET_PROC = ->(to, bot) { Cinch::Target.new(to, bot) }

    # 初期化する
    # @param [Cinch::Bot] bot Cinchボット
    # @param [Cinch::User] sender メッセージの送信者
    # @param [Proc] new_target_proc IRCメッセージの送信対象オブジェクトを作る手続き
    def initialize(bot, sender, new_target_proc = DEFAULT_NEW_TARGET_PROC)
      @bot = bot
      @sender = sender
      @new_target_proc = new_target_proc
    end

    # 指定したチャンネルにメッセージを送信する
    #
    # BCDiceとインターフェースを合わせるためのメソッド。
    #
    # @param [String] to 送信先（チャンネル、ユーザー）
    # @param [String] message BCDiceが生成した、送信するメッセージ
    # @return [void]
    def sendMessage(to, message)
      target = @new_target_proc[to, @bot]
      target.notice(message)
    end

    # メッセージの送信者に返信する
    #
    # @param [String] _nick 送信者のニックネーム（使用しない）
    # @param [String] message BCDiceが生成した、返信するメッセージ
    # @return [void]
    def sendMessageToOnlySender(_nick, message)
      @sender.notice(message)
    end

    # 全チャンネルにメッセージを送信する
    # @param [String] message BCDiceが生成した、送信するメッセージ
    # @return [void]
    def sendMessageToChannels(message)
      @bot.channels.each do |channel|
        channel.notice(message)
      end
    end
  end
end
