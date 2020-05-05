# frozen_string_literal: true

require 'cinch'

module BCDiceIRC
  module GUI
    class Mediator
      attr_reader :irc_bot

      def initialize(app, log_level = :info)
        @app = app

        @queue = Queue.new
        @thread = nil
        @irc_bot = nil
        @irc_bot_thread = nil
        @logger = Cinch::Logger::FormattedLogger.new($stderr, level: log_level)
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
        @irc_bot.bot.loggers[0] = @logger
      end

      def start_irc_bot!
        return false if @irc_bot_thread

        @irc_bot_thread = Thread.new do
          log_exception = true

          begin
            success = @irc_bot.start!
            if success
              @queue.push([:irc_bot_stopped])
            else
              log_exception = false
              raise @irc_bot.last_connection_exception
            end
          rescue => e
            @logger.exception(e) if log_exception
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
        @logger.debug('Mediator: thread start')

        loop do
          message, *args = @queue.pop
          case message
          when :quit
            on_quit
            break
          when :quit_irc_bot
            on_quit_irc_bot
          when :irc_bot_stopped
            on_irc_bot_stopped
          when :successfully_connected
            on_successfully_connected
          when :connection_error
            on_connection_error(args[0])
          end
        end

        @logger.debug('Mediator: thread end')
      end

      def on_quit
        if @irc_bot_thread
          @logger.debug('Mediator: IRC bot is running. Try to quit it.')

          @irc_bot.quit!
          @irc_bot_thread.join
          @logger.debug('Mediator: IRC bot has stopped')

          @irc_bot_thread = nil
        end
      end

      def on_quit_irc_bot
        @irc_bot.quit! if @irc_bot_thread
      end

      def on_irc_bot_stopped
        @irc_bot_thread = nil

        @app.in_idle_time do
          @app.switch_to_disconnected_state
        end
      end

      def on_successfully_connected
        @app.in_idle_time do
          @app.switch_to_connected_state
        end
      end

      # @param [StandardError] e 発生した例外
      def on_connection_error(e)
        @app.in_idle_time do
          @app.switch_to_disconnected_state(true)
          @app.show_connection_error_dialog(e)
        end
      end
    end
  end
end
