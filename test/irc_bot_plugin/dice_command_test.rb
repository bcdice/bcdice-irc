# frozen_string_literal: true

require_relative '../test_helper'

module BCDiceIRC
  module IRCBotPlugin
    class TestDiceCommand < Test::Unit::TestCase
      include Cinch::Test
      include IRCBotTestHelper

      setup do
        bcdice_maker = BCDiceMaker.new
        @bcdice = bcdice_maker.newBcDice
        @bcdice.setGameByTitle('DiceBot')

        plugin_config = IRCBotPluginConfig.new(
          bcdice: @bcdice,
          mediator: nil,
        )

        @bot = make_cinch_bot([DiceCommand], plugin_config)
        @bot.config.channels = %w(#test #test2)
      end

      test 'should respond to an AddDice message' do
        message = make_message(@bot, '2d6', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_match(/\Atest: \(2D6\)/, reply.text)
      end
    end
  end
end
