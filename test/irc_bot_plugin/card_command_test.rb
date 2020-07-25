# frozen_string_literal: true

require_relative '../test_helper'

module BCDiceIRC
  module IRCBotPlugin
    class TestCardCommand < Test::Unit::TestCase
      include Cinch::Test
      include IRCBotTestHelper

      setup do
        bcdice_maker = BCDiceMaker.new
        @bcdice = bcdice_maker.newBcDice
        @bcdice.setGameByTitle('DiceBot')
        @bcdice.cardTrader.initValues

        plugin_config = IRCBotPluginConfig.new(
          bcdice: @bcdice,
          mediator: nil,
        )

        @bot = make_cinch_bot([DiceCommand, CardCommand], plugin_config)
        @bot.config.channels = %w(#test #test2)
      end

      data('c-shuffle', 'c-shuffle')
      data('c-sh', 'c-sh')
      test 'can shuffle cards' do |data|
        command = data
        message = make_message(@bot, command, channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('シャッフルしました', reply.text)
      end

      data('J1', ['J1', [[53, 53]]])
      data('C13', ['C13', [[52, 53]]])
      data('S1', ['S1', [[1, 53]]])
      test 'can draw a card' do |data|
        card, rand_values = data
        @bcdice.setRandomValues(rand_values)

        message = make_message(@bot, 'c-draw', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('test: 1枚引きました', reply.text)

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_equal(card, reply.text)
      end

      test 'can draw three cards' do
        @bcdice.setRandomValues([[1, 53], [1, 52], [51, 51]])

        message = make_message(@bot, 'c-draw[3]', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('test: 3枚引きました', reply.text)

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_equal('J1,S1,S2', reply.text)
      end

      data('c-draw', 'c-draw')
      data('c-odraw', 'c-odraw')
      test 'cannot draw a card without remaining cards' do |data|
        command = data

        rand_values = 53.downto(1).map { |max| [1, max] }
        @bcdice.setRandomValues(rand_values)
        message_53 = make_message(@bot, 'c-draw[53]', channel: '#test')
        get_bcdice_replies(message_53)

        @bcdice.setRandomValues([[1, 0]])
        message = make_message(@bot, command, channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('カードが残っていません', reply.text)
      end

      test 'can draw openly a card' do
        @bcdice.setRandomValues([[53, 53]])

        message = make_message(@bot, 'c-odraw', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('test: J1を引きました', reply.text)

        assert_equal(0, bcdice_reply.direct_messages.length)
      end

      test 'can draw openly three cards' do
        @bcdice.setRandomValues([[1, 53], [1, 52], [51, 51]])

        message = make_message(@bot, 'c-odraw[3]', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('test: J1,S1,S2を引きました', reply.text)

        assert_equal(0, bcdice_reply.direct_messages.length)
      end

      test 'cannot show hands without them' do
        message = make_message(@bot, 'c-hand', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        assert_nil(bcdice_reply.channel_messages['#test'])

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_equal(
          'カードを持っていません 場札:[  ] タップした場札:[  ]',
          reply.text
        )
      end

      test 'can show hands' do
        @bcdice.setRandomValues([[1, 53], [1, 52], [51, 51]])

        message_draw_3 = make_message(@bot, 'c-draw[3]', channel: '#test')
        get_bcdice_replies(message_draw_3)

        message = make_message(@bot, 'c-hand', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        assert_nil(bcdice_reply.channel_messages['#test'])

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_equal('[ J1,S1,S2 ] 場札:[  ] タップした場札:[  ]', reply.text)
      end

      test "can show user's hands" do
        @bcdice.setRandomValues([[1, 53], [1, 52], [51, 51]])

        message_draw_3 = make_message(@bot, 'c-draw[3]', channel: '#test')
        get_bcdice_replies(message_draw_3)

        message = make_message(@bot, 'c-vhand test', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        assert_nil(bcdice_reply.channel_messages['#test'])

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_equal('test の手札は [ J1,S1,S2 ] 場札:[  ] タップした場札:[  ] です', reply.text)
      end

      test 'can play a card' do
        @bcdice.setRandomValues([[1, 53], [1, 52], [51, 51]])

        message_draw_3 = make_message(@bot, 'c-draw[3]', channel: '#test')
        get_bcdice_replies(message_draw_3)

        message = make_message(@bot, 'c-play[S1]', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('test: 1枚出しました', reply.text)

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_equal('[ J1,S2 ] 場札:[  ] タップした場札:[  ]', reply.text)
      end

      data('c-play', 'c-play[C1]')
      data('c-play1', 'c-play1[C1]')
      test 'cannot play a card not in the hands' do |data|
        command = data

        @bcdice.setRandomValues([[1, 53]])

        message_draw = make_message(@bot, 'c-draw', channel: '#test')
        get_bcdice_replies(message_draw)

        message_play_s1 = make_message(@bot, 'c-play[S1]', channel: '#test')
        get_bcdice_replies(message_play_s1)

        message = make_message(@bot, command, channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('[C1]は持っていません', reply.text)

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_equal('[  ] 場札:[  ] タップした場札:[  ]', reply.text)
      end

      test 'can play openly a card' do
        @bcdice.setRandomValues([[1, 53], [1, 52], [51, 51]])

        message_draw_3 = make_message(@bot, 'c-draw[3]', channel: '#test')
        get_bcdice_replies(message_draw_3)

        message = make_message(@bot, 'c-play1[S1]', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('test: 1枚出しました', reply.text)

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_equal('[ J1,S2 ] 場札:[ S1 ] タップした場札:[  ]', reply.text)
      end

      test 'can play openly multiple cards' do
        @bcdice.setRandomValues([[1, 53], [1, 52], [51, 51]])

        message_draw_3 = make_message(@bot, 'c-draw[3]', channel: '#test')
        get_bcdice_replies(message_draw_3)

        message = make_message(@bot, 'c-play1[J1,S2]', channel: '#test')
        bcdice_reply = get_bcdice_replies(message)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('test: 2枚出しました', reply.text)

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_equal('[ S1 ] 場札:[ J1,S2 ] タップした場札:[  ]', reply.text)
      end

      test 'can put discards into the stock' do
        @bcdice.setRandomValues([[1, 53], [1, 52], [51, 51]])

        message_draw_3 = make_message(@bot, 'c-draw[3]', channel: '#test')
        get_bcdice_replies(message_draw_3)

        message_play_2 = make_message(@bot, 'c-play[S1,J1]', channel: '#test')
        get_bcdice_replies(message_play_2)

        message_rshuffle = make_message(@bot, 'c-rshuffle', channel: '#test')
        bcdice_reply = get_bcdice_replies(message_rshuffle)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('捨て札を山に戻しました', reply.text)

        assert_equal(0, bcdice_reply.direct_messages.length)

        @bcdice.setRandomValues([[52, 52]])

        message_draw = make_message(@bot, 'c-odraw[1]', channel: '#test')
        bcdice_reply = get_bcdice_replies(message_draw)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('test: J1を引きました', reply.text)
      end
    end
  end
end
