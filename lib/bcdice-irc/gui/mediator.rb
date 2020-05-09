# frozen_string_literal: true

require_relative '../categorizable_logger'
require_relative '../irc_bot'

module BCDiceIRC
  module GUI
    # IRCボットとGUIとの仲介のクラス
    class Mediator
      # IRCボット
      # @return [IRCBot]
      attr_reader :irc_bot

      # 仲介処理を初期化する
      # @param [Application] app GUIアプリ
      # @param [Symbol] log_level ログレベル
      def initialize(app, log_level)
        @app = app
        @log_level = log_level

        @logger = CategorizableLogger.new('Mediator', $stderr, level: log_level)

        @queue = Queue.new
        @thread = nil
        @irc_bot = nil
        @irc_bot_thread = nil
      end

      # 仲介スレッドを起動する
      #
      # 既に仲介スレッドが起動している場合は何もしない。
      #
      # @return [Boolean] 仲介スレッドを起動したか
      def start!
        return false if @thread

        @thread = Thread.new do
          thread_proc
        end

        return true
      end

      # 仲介スレッドを終了させる
      #
      # 仲介スレッドが起動していない場合は何もしない。
      # スレッドが終了するまでは待機する。
      #
      # @return [Boolean] 終了に成功したか
      def quit!
        return false unless @thread

        @queue.push([:quit])
        @thread.join

        @thread = nil

        return true
      end

      # IRCボットを起動する
      #
      # 既にIRCボットが起動している場合は何もしない。
      #
      # @param [IRCBot::Config] irc_bot_config IRCボットの設定
      # @return [Boolean] IRCボットの起動を試したか
      def start_irc_bot(irc_bot_config)
        return false if @irc_bot_thread

        @irc_bot = IRCBot.new(irc_bot_config, self, @log_level)
        @irc_bot_thread = Thread.new do
          irc_bot_thread_proc
        end

        return true
      end

      # IRCボットを終了させる
      def quit_irc_bot
        @queue.push([:quit_irc_bot])
      end

      # 接続成功を通知する
      def notify_successfully_connected
        @queue.push([:successfully_connected])
      end

      # ゲームシステムが変更されたことを通知する
      # @param [String] game_system_name ゲームシステム名
      # @return [void]
      def notify_game_system_has_been_changed(game_system_name)
        @queue.push([:game_system_has_been_changed, game_system_name])
      end

      private

      # 仲介スレッドの処理
      # @return [void]
      def thread_proc
        @logger.debug('Mediator thread start')

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
          when :game_system_has_been_changed
            on_game_system_has_been_changed(args[0])
          end
        end

        @logger.debug('Mediator thread end')
      end

      # 仲介スレッド終了メッセージに対する処理
      # @return [self]
      def on_quit
        if @irc_bot_thread
          @logger.debug('IRC bot thread is running. Try to stop it.')

          @irc_bot.quit!
          @irc_bot_thread.join
          @logger.debug('IRC bot thread has stopped')

          @irc_bot_thread = nil
        end

        self
      end

      # IRCボットを終了させるメッセージに対する処理
      # @return [self]
      def on_quit_irc_bot
        @irc_bot.quit! if @irc_bot_thread
        self
      end

      # IRCボット停止メッセージに対する処理
      # @return [self]
      def on_irc_bot_stopped
        @irc_bot_thread = nil

        @app.in_idle_time do
          @app.change_state(:disconnected)
        end

        self
      end

      # 接続成功メッセージに対する処理
      # @return [self]
      def on_successfully_connected
        @app.in_idle_time do
          @app.change_state(:connected)
        end

        self
      end

      # 接続エラーメッセージに対する処理
      # @param [StandardError] e 発生した例外
      # @return [self]
      def on_connection_error(e)
        @app.in_idle_time do
          @app.notify_connection_error(e)
        end

        self
      end

      # ゲームシステムが変更された場合のメッセージに対する処理
      # @param [String] game_system_name ゲームシステム名
      # @return [self]
      def on_game_system_has_been_changed(game_system_name)
        @app.in_idle_time do
          @app.game_system_name = game_system_name
        end

        self
      end

      # IRCボットスレッドの処理
      # @return [void]
      def irc_bot_thread_proc
        @logger.debug('IRC bot thread start')

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
          @irc_bot_thread = nil

          @logger.exception(e) if log_exception
          @queue.push([:connection_error, e])
        end

        @logger.debug('IRC bot thread end')
      end
    end
  end
end
