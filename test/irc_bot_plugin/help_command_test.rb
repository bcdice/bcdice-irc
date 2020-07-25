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

        @bot = make_cinch_bot([HelpCommand], plugin_config)
        @bot.config.channels = %w(#test #test2)
      end

      test 'should not respond to a public message' do
        message = make_message(@bot, 'Help', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        assert(bcdice_reply.channel_messages.empty?)

        message = make_message(@bot, 'C-Help', channel: '#test')
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

      test 'DiceBot help message' do
        message = make_message(@bot, 'Help')
        bcdice_reply = get_bcdice_replies(message)

        messages = bcdice_reply.direct_messages.map(&:text)

        help_message_1_last_line_index =
          messages.find_index { |m| m.start_with?('* 四則演算') }

        separator_line_1 = messages[help_message_1_last_line_index + 1]
        assert_equal('----', separator_line_1)

        help_message_2_first_line = messages[help_message_1_last_line_index + 2]
        assert_match(/\A\* プロット表示/, help_message_2_first_line)
      end

      test 'Cthulhu help message' do
        @bcdice.setGameByTitle('Cthulhu')

        message = make_message(@bot, 'Help')
        bcdice_reply = get_bcdice_replies(message)

        messages = bcdice_reply.direct_messages.map(&:text)

        help_message_1_last_line_index =
          messages.find_index { |m| m.start_with?('* 四則演算') }

        separator_line_1 = messages[help_message_1_last_line_index + 1]
        assert_equal('----', separator_line_1)

        cthulhu_first_line = messages[help_message_1_last_line_index + 2]
        assert_match(/\Ac=クリティカル値/, cthulhu_first_line)

        help_message_2_first_line_index =
          messages.find_index { |m| m.match?(/\A\* プロット表示/) }
        separator_line_2 = messages[help_message_2_first_line_index - 1]
        assert_equal('----', separator_line_2)
      end

      test 'should not respond to pseudo help messages' do
        message = make_message(@bot, '_Help')
        bcdice_reply = get_bcdice_replies(message)

        assert(bcdice_reply.channel_messages.empty?)

        message = make_message(@bot, 'Help_')
        bcdice_reply = get_bcdice_replies(message)

        assert(bcdice_reply.channel_messages.empty?)
      end

      test 'c-help' do
        message = make_message(@bot, 'C-Help')
        bcdice_reply = get_bcdice_replies(message)

        assert_operator(2, :<, bcdice_reply.direct_messages.length)
        assert(bcdice_reply.direct_messages.all? { |m| m.event == :notice })
        assert_match(/END/, bcdice_reply.direct_messages.last.text)
      end

      test 'should not respond to pseudo c-help messages' do
        message = make_message(@bot, '_C-Help')
        bcdice_reply = get_bcdice_replies(message)

        assert(bcdice_reply.channel_messages.empty?)

        message = make_message(@bot, 'C-Help_')
        bcdice_reply = get_bcdice_replies(message)

        assert(bcdice_reply.channel_messages.empty?)
      end
    end
  end
end
