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
        message = make_message(@bot, 'Set Game->Cthulhu')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal('Cthulhu', @bcdice.getGameType)
        assert_equal('クトゥルフ', @mediator.game_system_name)
        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('Game設定をクトゥルフに設定しました', reply.text)
      end

      test 'set game to an unknown game system' do
        message = make_message(@bot, 'Set Game->Unknown')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal('DiceBot', @bcdice.getGameType)
        assert_equal('DiceBot', @mediator.game_system_name)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('Game設定をDiceBotに設定しました', reply.text)
      end

      test 'set master without nick' do
        message = make_message(@bot, 'Set Master')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal('test', @bcdice_maker.master)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('testさんをMasterに設定しました', reply.text)

        message = make_message(@bot, 'Set Master')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal('', @bcdice_maker.master)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('Master設定を解除しました', reply.text)
      end

      test 'set master with nick' do
        message = make_message(@bot, 'Set Master->foo')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal('foo', @bcdice_maker.master)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('fooさんをMasterに設定しました', reply.text)
      end

      test 'set master without nick when master is not bot' do
        message = make_message(@bot, 'Set Master->foo')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal('foo', @bcdice_maker.master)

        message = make_message(@bot, 'Set Master')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal('foo', @bcdice_maker.master)

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_equal('Masterはfooさんになっています', reply.text)
      end

      test 'set upper' do
        message = make_message(@bot, 'Set Upper->5')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(5, @bcdice_maker.diceBot.upplerRollThreshold)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('上方無限ロールを5以上に設定しました', reply.text)
      end

      test 'clear upper' do
        message = make_message(@bot, 'Set Upper->0')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(0, @bcdice_maker.diceBot.upplerRollThreshold)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('上方無限ロールの閾値設定を解除しました', reply.text)
      end

      test 'set reroll' do
        message = make_message(@bot, 'Set Reroll->100')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(100, @bcdice_maker.diceBot.rerollLimitCount)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('個数振り足しロール回数を100以下に設定しました', reply.text)
      end

      test 'clear reroll' do
        message = make_message(@bot, 'Set Reroll->0')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(0, @bcdice_maker.diceBot.rerollLimitCount)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('個数振り足しロールの回数を無限に設定しました', reply.text)
      end

      test 'set to sort values' do
        message = make_message(@bot, 'Set Sort->3')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(3, @bcdice_maker.diceBot.sortType)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('ソート有りに変更しました', reply.text)
      end

      test 'set not to sort values' do
        message = make_message(@bot, 'Set Sort->0')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(0, @bcdice_maker.diceBot.sortType)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('ソート無しに変更しました', reply.text)
      end

      test 'can set view mode when master is not set' do
        message = make_message(@bot, 'Set ViewMode->0')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(0, @bcdice_maker.diceBot.sendMode)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('ViewMode0に変更しました', reply.text)
      end

      test 'can set view mode when master is bot' do
        message = make_message(@bot, 'set master')
        bcdice_reply = get_bcdice_replies(message)

        message = make_message(@bot, 'Set ViewMode->0')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(0, @bcdice_maker.diceBot.sendMode)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('ViewMode0に変更しました', reply.text)
      end

      test 'cannot set view mode when master is not bot' do
        @bcdice_maker.diceBot.setSendMode(2)

        message = make_message(@bot, 'Set Master->foo')
        bcdice_reply = get_bcdice_replies(message)

        message = make_message(@bot, 'Set ViewMode->0')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(2, @bcdice_maker.diceBot.sendMode)
        assert_equal(0, bcdice_reply.direct_messages.length)
      end

      test 'can set to use card place when master is not set' do
        message = make_message(@bot, 'Set CardPlace->1')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(1, @bcdice.cardTrader.card_place)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('カード置き場ありに変更しました', reply.text)
      end

      test 'can set not to use card place when master is not set' do
        message = make_message(@bot, 'Set CardPlace->0')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(0, @bcdice.cardTrader.card_place)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('カード置き場無しに変更しました', reply.text)
      end

      test 'can set to use card place when master is bot' do
        message = make_message(@bot, 'Set Master')
        bcdice_reply = get_bcdice_replies(message)

        message = make_message(@bot, 'Set CardPlace->1')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(1, @bcdice.cardTrader.card_place)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('カード置き場ありに変更しました', reply.text)
      end

      test 'cannot set to use card place when master is not bot' do
        @bcdice.cardTrader.card_place = 0

        message = make_message(@bot, 'Set Master->foo')
        bcdice_reply = get_bcdice_replies(message)

        message = make_message(@bot, 'Set CardPlace->1')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(0, @bcdice.cardTrader.card_place)
        assert_equal(0, bcdice_reply.channel_messages.length)
      end

      test 'can set no tap when master is not set' do
        message = make_message(@bot, 'Set Tap->0')
        bcdice_reply = get_bcdice_replies(message)

        assert_false(@bcdice.cardTrader.canTapCard)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('タップ不可モードに変更しました', reply.text)
      end

      test 'can set tap when master is not set' do
        message = make_message(@bot, 'Set Tap->1')
        bcdice_reply = get_bcdice_replies(message)

        assert_true(@bcdice.cardTrader.canTapCard)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('タップ可能モードに変更しました', reply.text)
      end

      test 'can set tap when master is bot' do
        message = make_message(@bot, 'Set Master')
        bcdice_reply = get_bcdice_replies(message)

        message = make_message(@bot, 'Set Tap->1')
        bcdice_reply = get_bcdice_replies(message)

        assert_true(@bcdice.cardTrader.canTapCard)

        assert_equal(2, bcdice_reply.channel_messages.length)

        replies_in_test = bcdice_reply.channel_messages['#test']
        assert_equal(1, replies_in_test.length)

        reply = replies_in_test[0]
        assert_equal(:notice, reply.event)
        assert_equal('タップ可能モードに変更しました', reply.text)
      end

      test 'cannot set tap when master is not bot' do
        @bcdice.cardTrader.card_place = false

        message = make_message(@bot, 'Set Master->foo')
        bcdice_reply = get_bcdice_replies(message)

        message = make_message(@bot, 'Set Tap->1')
        bcdice_reply = get_bcdice_replies(message)

        assert_false(@bcdice.cardTrader.card_place)
        assert_equal(0, bcdice_reply.channel_messages.length)
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

      test 'can check mode when master is not set' do
        message = make_message(@bot, 'Mode')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_match(/\AGameType = [^,]+, ViewMode = \d+, Sort = \d+/, reply.text)
      end

      test 'can check mode when master is bot' do
        message = make_message(@bot, 'set master')
        bcdice_reply = get_bcdice_replies(message)

        message = make_message(@bot, 'Mode')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(1, bcdice_reply.direct_messages.length)

        reply = bcdice_reply.direct_messages[0]
        assert_equal(:notice, reply.event)
        assert_match(/\AGameType = [^,]+, ViewMode = \d+, Sort = \d+/, reply.text)
      end

      test 'cannot check mode when master is not bot' do
        message = make_message(@bot, 'Set Master->foo')
        bcdice_reply = get_bcdice_replies(message)

        message = make_message(@bot, 'Mode')
        bcdice_reply = get_bcdice_replies(message)

        assert_equal(0, bcdice_reply.direct_messages.length)
      end
    end
  end
end
