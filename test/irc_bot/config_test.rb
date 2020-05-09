# frozen_string_literal: true

require_relative '../test_helper'

module BCDiceIRC
  class IRCBot
    class ConfigTest < Test::Unit::TestCase
      CONFIG_HASH = {
        name: 'Config 1',
        hostname: 'irc.trpg.net',
        port: 6667,
        password: 'p@ssw0rd',
        nick: 'BCDice',
        channel: '#Dice_Test',
        quit_message: 'さようなら',
        game_system_id: 'DiceBot'
      }.freeze

      CONFIG_HASH_WITH_STR_KEYS = {
        'name' => 'Config 1',
        'hostname' => 'irc.trpg.net',
        'port' => 6667,
        'password' => 'p@ssw0rd',
        'nick' => 'BCDice',
        'channel' => '#Dice_Test',
        'quit_message' => 'さようなら',
        'game_system_id' => 'DiceBot'
      }.freeze

      setup do
        @config = Config.new(
          name: 'Config 1',
          hostname: 'irc.trpg.net',
          port: 6667,
          password: 'p@ssw0rd',
          nick: 'BCDice',
          channel: '#Dice_Test',
          quit_message: 'さようなら',
          game_system_id: 'DiceBot'
        )
      end

      test '既定値が正しい' do
        expected = Config.new(
          name: 'デフォルト',
          hostname: 'irc.trpg.net',
          port: 6667,
          password: nil,
          nick: 'BCDice',
          channel: '#Dice_Test',
          quit_message: 'さようなら',
          game_system_id: 'DiceBot'
        )

        assert_equal(expected, Config::DEFAULT)
      end

      test '#to_h の結果が正しい' do
        assert_equal(CONFIG_HASH, @config.to_h)
      end

      data('キーがシンボルの場合', CONFIG_HASH)
      data('キーが文字列の場合', CONFIG_HASH_WITH_STR_KEYS)
      test '.from_hash の結果が正しい' do
        assert_equal(@config, Config.from_hash(data))
      end
    end
  end
end
