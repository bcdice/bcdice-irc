# frozen_string_literal: true

require_relative 'cinch_mod'

module BCDiceIRC
  module GUI
    class Mediator
      attr_reader :irc_bot

      def initialize(app)
        @app = app

        @queue = Queue.new
        @thread = nil
        @irc_bot = nil
        @irc_bot_thread = nil
      end

      def start!
        return false if @thread

        @thread = Thread.new do
          thread_proc
        end

        return true
      end

      def quit!
        return false unless @thread

        @queue.push([:quit])
        @thread.join

        @thread = nil

        return true
      end

      # IRCボットを作成する
      # @param [IRCBot::Config] config IRCボットの設定
      # @param [String] game_system_id ゲームシステムID
      def create_irc_bot(config, game_system_id)
        @irc_bot = IRCBot.new(config, self, game_system_id)
      end

      def start_irc_bot!
        return false if @irc_bot_thread

        @irc_bot_thread = Thread.new do
          begin
            success = @irc_bot.start!
            if success
              @queue.push([:irc_bot_stopped])
            else
              raise @irc_bot.last_connection_error
            end
          rescue => e
            puts("IRC bot start error:\n#{e.full_message(order: :top)}")
            @queue.push([:connection_error, e])
            @irc_bot_thread = nil
          end
        end

        return true
      end

      def quit_irc_bot!
        @queue.push([:quit_irc_bot])
      end

      def notify_successfully_connected!
        @queue.push([:successfully_connected])
      end

      private

      def thread_proc
        puts('MediatorThread: start')

        loop do
          message, *args = @queue.pop
          case message
          when :quit
            if @irc_bot_thread
              puts('IRC bot is running. Try to quit it.')
              @irc_bot.quit!
              @irc_bot_thread.join
              puts('IRC bot is stopped.')

              @irc_bot_thread = nil
            end

            break
          when :quit_irc_bot
            next unless @irc_bot_thread
            @irc_bot.quit!
          when :irc_bot_stopped
            @irc_bot_thread = nil
            @app.switch_to_disconnected_state
          when :successfully_connected
            @app.switch_to_connected_state
          when :connection_error
            @app.switch_to_disconnected_state_with_error(*args)
          end
        end

        puts('MediatorThread: end')
      end
    end
  end
end
