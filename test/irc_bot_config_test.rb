# frozen_string_literal: true

require_relative 'test_helper'

module BCDiceIRC
  class IRCBotConfigTest < Test::Unit::TestCase
    CONFIG_HASH = {
      name: 'Config 1',
      hostname: 'irc.example.net',
      port: 6664,
      password: 'p@ssw0rd',
      encoding: 'ISO-2022-JP',
      nick: 'DiceBot',
      channel: '#DiceTest',
      quit_message: 'Bye',
      game_system_id: 'Cthulhu'
    }.freeze

    CONFIG_HASH_WITH_STR_KEYS = {
      'name' => 'Config 1',
      'hostname' => 'irc.example.net',
      'port' => 6664,
      'password' => 'p@ssw0rd',
      'encoding' => 'ISO-2022-JP',
      'nick' => 'DiceBot',
      'channel' => '#DiceTest',
      'quit_message' => 'Bye',
      'game_system_id' => 'Cthulhu'
    }.freeze

    setup do
      @config = IRCBotConfig.new(
        name: 'Config 1',
        hostname: 'irc.example.net',
        port: 6664,
        password: 'p@ssw0rd',
        encoding: NAME_TO_ENCODING['ISO-2022-JP'],
        nick: 'DiceBot',
        channel: '#DiceTest',
        quit_message: 'Bye',
        game_system_id: 'Cthulhu'
      )
    end

    test '既定値が正しい' do
      expected = IRCBotConfig.new(
        name: 'デフォルト',
        hostname: 'irc.trpg.net',
        port: 6667,
        encoding: NAME_TO_ENCODING['UTF-8'],
        password: nil,
        nick: 'BCDice',
        channel: '#Dice_Test',
        quit_message: 'さようなら',
        game_system_id: 'DiceBot'
      )

      assert_equal(expected, IRCBotConfig::DEFAULT)
    end

    test '#to_h の結果が正しい' do
      assert_equal(CONFIG_HASH, @config.to_h)
    end

    data('キーがシンボルの場合', CONFIG_HASH)
    data('キーが文字列の場合', CONFIG_HASH_WITH_STR_KEYS)
    test '.from_hash の結果が正しい' do
      assert_equal(@config, IRCBotConfig.from_hash(data))
    end

    test '#end_point' do
      assert_equal('irc.example.net:6664', @config.end_point)
    end
  end
end
