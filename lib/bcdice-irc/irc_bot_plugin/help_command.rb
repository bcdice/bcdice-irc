# frozen_string_literal: true

require 'cinch'

require 'bcdiceCore'

require_relative '../irc_message_sink'

module BCDiceIRC
  module IRCBotPlugin
    # ヘルプコマンドを実行するプラグイン
    class HelpCommand
      include Cinch::Plugin

      self.plugin_name = 'HelpCommand'
      self.prefix = ''

      match(/\Ahelp\z/i, method: :help)
      match(/\Ac-help\z/i, method: :c_help)

      # 区切り線
      SEPARATOR = '----'

      # 説明文の終わりの行
      END_LINE = '-- END --'

      # 説明文（ゲームシステム固有コマンドの説明の前）
      HELP_MESSAGE_1 = <<~HELP.chomp.freeze
        * 加算ロール                  xDn（n面体ダイスをx個）
        * バラバラロール              xBn
        * 個数振り足しロール          xRn[振り足し値]
        * 上方無限ロール              xUn[境界値]
        * シークレットロール          Sダイスコマンド
        * シークレットをオープンする  #{$OPEN_DICE}
        * 四則演算（端数切捨て）      C(式)
      HELP

      # 説明文（ゲームシステム固有コマンドの説明の後）
      HELP_MESSAGE_2 = <<~HELP.chomp.freeze
        #{SEPARATOR}
        * プロット表示                #{$OPEN_PLOT}
        * プロット記録                Talkで #{$ADD_PLOT}:プロット
        #{SEPARATOR}
        * ポイントカウンタ値登録      #[名前:]タグn[/m]（識別名・最大値省略可、Talk可）
        * カウンタ値操作              #[名前:]タグ+n（もちろん-nもOK、Talk可）
        * 識別名変更                  #RENAME!名前1->名前2（Talk可）
        * 同一タグのカウンタ値一覧    #OPEN!タグ
        * 自キャラのカウンタ値一覧    Talkで #OPEN![タグ]（全カウンタ表示時、タグ省略）
        * 自キャラのカウンタ削除      #[名前:]DIED!（デフォルト時、識別名省略）
        * 全自キャラのカウンタ削除    #ALL!:DIED!
        * カウンタ表示チャンネル登録  #{$READY_CMD}
        #{SEPARATOR}
        * カード機能ヘルプ            c-help
        #{END_LINE}
      HELP

      # カード機能の説明文
      C_HELP_MESSAGE = <<~C_HELP.chomp.freeze
        * カードを引く                c-draw[n]（nは枚数）
        * オープンでカードを引く      c-odraw[n]
        * カードを選んで引く          c-pick[c[,c]]（cはカード。カンマで複数指定可）
        * 捨てたカードを手札に戻す    c-back[c[,c]]
        * 置いたカードを手札に戻す    c-back1[c[,c]]
        * 手札と場札を見る            c-hand（Talk可）
        * カードを出す                c-play[c[,c]]
        * カードを場に出す            c-play1[c[,c]]
        * カードを捨てる              c-discard[c[,c]]（Talk可）
        * 場のカードを選んで捨てる    c-discard1[c[,c]]
        * 山札からめくって捨てる      c-milstone[n]
        * カードを相手に一枚渡す      c-pass[c]相手（カード指定がないときはランダム）
        * 場のカードを相手に渡す      c-pass1[c]相手（カード指定がないときはランダム）
        * カードを相手の場に出す      c-place[c[,c]]相手
        * 場のカードを相手の場に出す  c-place1[c[,c]]相手
        * 場のカードをタップする      c-tap1[c[,c]]相手
        * 場のカードをアンタップする  c-untap1[c[,c]]相手
        #{SEPARATOR}
        * カードを配る                c-deal[n]相手
        * カードを見てから配る        c-vdeal[n]相手
        * カードのシャッフル          c-shuffle
        * 捨てカードを山に戻す        c-rshuffle
        * 全員の場のカードを捨てる    c-clean
        * 相手の手札と場札を見る      c-vhand（Talk不可）
        * 枚数配置を見る              c-check
        * 復活の呪文を表示する        c-spell
        * 復活の呪文を唱える          c-spell[呪文]
        #{END_LINE}
      C_HELP

      # プラグインを初期化する
      def initialize(*)
        super

        @bcdice = config.bcdice
      end

      private

      # ヘルプコマンドに対する処理
      # @param [Cinch::Message] m メッセージ
      # @return [void]
      def help(m)
        # ボットに直接送られていないメッセージは無視する
        return if m.channel || m.target != m.user

        notice_each_line(m.user, HELP_MESSAGE_1)

        # ゲームシステムを指定している場合、固有の説明文を挿入する

        dice_bot_help_message = @bcdice.diceBot.help_message.chomp
        unless dice_bot_help_message.empty?
          m.user.notice(SEPARATOR)
          notice_each_line(m.user, dice_bot_help_message)
        end

        notice_each_line(m.user, HELP_MESSAGE_2)
      end

      # カード機能のヘルプコマンドに対する処理
      # @param [Cinch::Message] m メッセージ
      # @return [void]
      def c_help(m)
        # ボットに直接送られていないメッセージは無視する
        return if m.channel || m.target != m.user

        notice_each_line(m.user, C_HELP_MESSAGE)
      end

      # メッセージの各行をNOTICEする
      # @param [Cinch::Target] target 送信対象
      # @param [String] message 送信するメッセージ
      # @return [void]
      def notice_each_line(target, message)
        message.each_line do |line|
          target.notice(line.chomp)
        end
      end
    end
  end
end
