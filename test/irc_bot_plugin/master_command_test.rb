# frozen_string_literal: true

require_relative '../test_helper'

module BCDiceIRC
  module IRCBotPlugin
    class TestMasterCommand < Test::Unit::TestCase
      class MockMediator
        attr_reader :game_system_name

        def notify_game_system_has_been_changed(game_system_name)
          @game_system_name = game_system_name
        end
      end

      include Cinch::Test
      include BCDiceIRC::IRCBotTestHelper

      setup do
        @bcdice_maker = BCDiceMaker.new
        @bcdice = @bcdice_maker.newBcDice
        @bcdice.setGameByTitle('DiceBot')

        @mediator = MockMediator.new

        plugin_config = IRCBotPluginConfig.new(
          bcdice: @bcdice,
          mediator: @mediator,
        )

        @bot = make_cinch_bot(MasterCommand, plugin_config)
        @bot.config.channels = %w(#test #test2)
      end

      test 'should not respond to a public message' do
        message = make_message(@bot, '2d6', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        assert(bcdice_reply.channel_messages.empty?)
      end

      test 'set game to Cthulhu' do
        message = make_message(@bot, 'set game->Cthulhu')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal('Cthulhu', @bcdice.getGameType)
        assert_equal('クトゥルフ', @mediator.game_system_name)
        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_match(/\AGame設定を/, reply.text)
      end

      test 'set game to an unknown game system' do
        message = make_message(@bot, 'set game->Unknown')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal('DiceBot', @bcdice.getGameType)
        assert_equal('DiceBot', @mediator.game_system_name)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_match(/\AGame設定を/, reply.text)
      end

      test 'set master' do
        message = make_message(@bot, 'set master')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal('test', @bcdice_maker.master)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_match(/さんをMasterに設定しました\z/, reply.text)
      end
    end
  end
end
