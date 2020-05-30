# frozen_string_literal: true

module BCDiceIRC
  # BCDiceからのメッセージの送信先
  class IRCMessageSink
    # ゲームシステム変更通知のメッセージの正規表現
    GAME_SYSTEM_HAS_BEEN_CHANGED_RE =
      /\AGame設定を(.+)に設定しました\z/.freeze

    # 変更後のゲームシステム名
    attr_reader :new_game_system_name

    # 初期化する
    # @param [Cinch::Bot] bot Cinchボット
    # @param [Cinch::User] sender メッセージの送信者
    def initialize(bot, sender)
      @bot = bot
      @sender = sender

      @new_game_system_name = nil
    end

    # 指定したチャンネルにメッセージを送信する
    #
    # BCDiceとインターフェースを合わせるためのメソッド。
    #
    # @param [String] channel チャンネル
    # @param [String] message BCDiceが生成した、送信するメッセージ
    # @return [void]
    def sendMessage(channel, message)
      target = Cinch::Target.new(channel, @bot)
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
      update_new_game_system_name(message)

      @bot.channels.each do |channel|
        channel.notice(message)
      end
    end

    private

    # new_game_system_nameを更新する
    # @param [String] message BCDiceが生成した、送信するメッセージ
    # @return [self]
    def update_new_game_system_name(message)
      m = message.match(GAME_SYSTEM_HAS_BEEN_CHANGED_RE)
      @new_game_system_name = m.to_a[1]

      self
    end
  end
end
