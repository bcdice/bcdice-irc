# frozen_string_literal: true

require 'forwardable'
require 'diceBot/DiceBot'

module BCDiceIRC
  # ダイスボットについての情報を含むラッパ
  module DiceBotWrapper
    # 汎用ダイスボット（DiceBot）用のラッパ
    class General
      extend Forwardable

      # @!attribute id
      #   @return [String] ゲームシステムID
      def_delegators(:@bot, :id)

      # ゲームシステム名
      # @return [String]
      NAME = 'ダイスボット（指定なし）'

      # ダイスボットの使い方
      # @return [String]
      HELP_MESSAGE = <<~MESSAGE_TEXT
        【ダイスボット】チャットにダイス用の文字を入力するとダイスロールが可能
        入力例）２ｄ６＋１　攻撃！
        出力例）2d6+1　攻撃！
        　　　　  diceBot: (2d6) → 7
        上記のようにダイス文字の後ろに空白を入れて発言する事も可能。
        以下、使用例
        　3D6+1>=9 ：3d6+1で目標値9以上かの判定
        　1D100<=50 ：D100で50％目標の下方ロールの例
        　3U6[5] ：3d6のダイス目が5以上の場合に振り足しして合計する(上方無限)
        　3B6 ：3d6のダイス目をバラバラのまま出力する（合計しない）
        　10B6>=4 ：10d6を振り4以上のダイス目の個数を数える
        　(8/2)D(4+6)<=(5*3)：個数・ダイス・達成値には四則演算も使用可能
        　C(10-4*3/2+2)：C(計算式）で計算だけの実行も可能
        　choice[a,b,c]：列挙した要素から一つを選択表示。ランダム攻撃対象決定などに
        　S3d6 ： 各コマンドの先頭に「S」を付けると他人結果の見えないシークレットロール
        　3d6/2 ： ダイス出目を割り算（切り捨て）。切り上げは /2U、四捨五入は /2R。
        　D66 ： D66ダイス。順序はゲームに依存。D66N：そのまま、D66S：昇順。
        MESSAGE_TEXT

      # @param [DiceBot] bot ダイスボット
      def initialize(bot)
        @bot = bot
      end

      # ゲームシステム名
      # @return [String]
      def name
        NAME
      end

      # ダイスボットの説明文
      # @return [String]
      def help_message
        HELP_MESSAGE
      end
    end

    # 特定のゲームシステム用のダイスボットのラッパ
    class GameSystemSpecified
      extend Forwardable

      # ダイスボットの説明文
      # @return [String]
      attr_reader :help_message

      # @!attribute [r] id
      #   @return [String] ゲームシステムID
      # @!attribute [r] name
      #   @return [String] ゲームシステム名
      def_delegators(:@bot, :id, :name)

      # @param [DiceBot] bot ダイスボット
      def initialize(bot)
        @bot = bot

        @help_message = bot.help_message.strip
      end
    end

    module_function

    # 指定されたボットを含むダイスボットラッパを返す
    # @param [DiceBot] bot ダイスボット
    # @return [General] 通常のダイスボットが渡された場合
    # @return [GameSystemSpecified] 特定のゲームシステム用のダイスボットが
    #   渡された場合
    def wrap(bot)
      if bot.class == DiceBot
        General.new(bot)
      else
        GameSystemSpecified.new(bot)
      end
    end
  end
end
