# frozen_string_literal: true

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
        new(
          name: fetch(hash, :name),
          hostname: fetch(hash, :hostname),
          port: fetch(hash, :port),
          password: fetch(hash, :password),
          nick: fetch(hash, :nick),
          channel: fetch(hash, :channel),
          quit_message: fetch(hash, :quit_message),
          game_system_id: fetch(hash, :game_system_id)
        )
      end

      private_class_method def self.fetch(hash, key)
        hash[key] || hash[key.to_s]
      end
    end
  end
end
