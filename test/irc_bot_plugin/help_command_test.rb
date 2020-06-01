# frozen_string_literal: true

require_relative '../test_helper'

module BCDiceIRC
  module IRCBotPlugin
    class TestHelpCommand < Test::Unit::TestCase
      include Cinch::Test
      include BCDiceIRC::IRCBotTestHelper

      setup do
        @bcdice_maker = BCDiceMaker.new
        @bcdice = @bcdice_maker.newBcDice
        @bcdice.setGameByTitle('DiceBot')

        plugin_config = IRCBotPluginConfig.new(
          bcdice: @bcdice,
        )

        @bot = make_cinch_bot(HelpCommand, plugin_config)
        @bot.config.channels = %w(#test #test2)
      end

      test 'should not respond to a public message' do
        message = make_message(@bot, '2d6', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        assert(bcdice_reply.channel_messages.empty?)
      end

      test 'help' do
        message = make_message(@bot, 'Help')
        bcdice_reply = get_bcdice_replies(message)

        assert_operator(2, :<, bcdice_reply.direct_messages.length)
        assert(bcdice_reply.direct_messages.all? { |m| m.event == :notice })
        assert_match(/END/, bcdice_reply.direct_messages.last.text)
      end

      test 'c-help' do
        message = make_message(@bot, 'C-Help')
        bcdice_reply = get_bcdice_replies(message)

        assert_operator(2, :<, bcdice_reply.direct_messages.length)
        assert(bcdice_reply.direct_messages.all? { |m| m.event == :notice })
        assert_match(/END/, bcdice_reply.direct_messages.last.text)
      end
    end
  end
end
