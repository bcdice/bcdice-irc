# frozen_string_literal: true

require 'active_support/core_ext/hash/keys'

module BCDiceIRC
  class IRCBot
    Config = Struct.new(
      :name,
      :hostname,
      :port,
      :password,
      :nick,
      :channel,
      :quit_message,
      :game_system_id,
      keyword_init: true
    )

    class Config
      DEFAULT = new(
        name: 'デフォルト',
        hostname: 'irc.trpg.net',
        port: 6667,
        password: nil,
        nick: 'BCDice',
        channel: '#Dice_Test',
        quit_message: 'さようなら',
        game_system_id: 'DiceBot'
      ).freeze

      def self.from_hash(hash)
        hash_with_sym_keys = hash.symbolize_keys
        new(
          name: hash_with_sym_keys[:name],
          hostname: hash_with_sym_keys[:hostname],
          port: hash_with_sym_keys[:port],
          password: hash_with_sym_keys[:password],
          nick: hash_with_sym_keys[:nick],
          channel: hash_with_sym_keys[:channel],
          quit_message: hash_with_sym_keys[:quit_message],
          game_system_id: hash_with_sym_keys[:game_system_id]
        )
      end

      # 接続先のエンドポイント（+ホスト名:ポート+）を返す
      # @return [String]
      def end_point
        "#{hostname}:#{port}"
      end
    end
  end
end
