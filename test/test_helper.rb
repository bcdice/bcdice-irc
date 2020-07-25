# frozen_string_literal: true

bcdice_dir = File.expand_path(File.join('..', 'vendor', 'bcdice', 'src'), __dir__)
lib_dir = File.expand_path(File.join('..', 'lib'), __dir__)
dirs = [bcdice_dir, lib_dir]
dirs.each do |dir|
  $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir)
end

require 'test/unit'

require 'cinch'
require 'cinch/test'

require 'bcdice-irc'

module BCDiceIRC
  module IRCBotTestHelper
    def make_cinch_bot(plugins = [], opts = {}, &block)
      bot = Cinch::Test::MockBot.new do
        loggers[0].level = :warn

        configure do |c|
          c.nick = 'testbot'
          c.server = nil
          c.channels = ['#test']
          c.reconnect = false

          plugins.each do |plugin|
            c.plugins.plugins.push(plugin)
            c.plugins.options[plugin] = opts
          end
        end

        instance_eval(&block) if block
      end
    end

    class BCDiceReplySet
      attr_reader :direct_messages
      attr_reader :channel_messages

      def initialize
        @direct_messages = []
        @channel_messages = {}
      end
    end

    # Process message and return all replies from BCDice.
    # @param [Cinch::Test::MockMessage] message A MockMessage object.
    # @param [Symbol] event The event type of the message.
    # @return [BCDiceReplySet]
    def get_bcdice_replies(message, event = :privmsg)
      mutex = Mutex.new
      bcdice_reply = BCDiceReplySet.new

      # Catch all user.(msg|send|privmsg)
      catch_direct_messages(message, mutex, bcdice_reply.direct_messages)

      # Catch all channel.send and action
      catch_channel_messages_from_bcdice(message.bot, mutex, bcdice_reply.channel_messages)

      # Catch all messages sent with IRCMessageSink#sendMessage
      catch_target_specified_messages(message, mutex, bcdice_reply)

      process_message(message, event)

      bcdice_reply
    end

    def catch_channel_messages_from_bcdice(bot, mutex, replies)
      bot.config.channels.each do |name|
        channel = Cinch::Channel.new(name, bot)

        channel.singleton_class.class_eval do
          define_method(:send) do |msg, notice = false|
            reply = Cinch::Test::Reply.new(msg, (notice ? :notice : :private), Time.now)

            mutex.synchronize do
              replies[name] ||= []
              replies[name].push(reply)
            end
          end

          define_method(:action) do |msg|
            reply = Cinch::Test::Reply.new(msg, :action, Time.now)

            mutex.synchronize do
              replies[name] ||= []
              replies[name].push(reply)
            end
          end
        end

        bot.channels.push(channel)
      end
    end

    def catch_target_specified_messages(message, mutex, bcdice_reply)
      plugin_config = message.bot.config.plugins.options.values[0]
      return unless plugin_config

      plugin_config.new_target_proc = lambda do |to, bot|
        target = Cinch::Target.new(to, bot)

        target.singleton_class.class_eval do
          define_method(:send) do |msg, notice = false|
            reply = Cinch::Test::Reply.new(msg, (notice ? :notice : :private), Time.now)

            if target.name.start_with?('#')
              mutex.synchronize do
                bcdice_reply.channel_messages[target.name] ||= []
                bcdice_reply.channel_messages[target.name].push(reply)
              end
            else
              mutex.synchronize do
                bcdice_reply.direct_messages.push(reply)
              end
            end
          end
        end

        target
      end
    end
  end
end
