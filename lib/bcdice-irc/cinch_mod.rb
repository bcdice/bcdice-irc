# frozen_string_literal: true

require 'nkf'
require 'cinch'

module BCDiceIRC
  class MyCinchBot < Cinch::Bot
    attr_accessor :last_connection_exception

    # Connects the bot to a server.
    #
    # @param [Boolean] plugins Automatically register plugins from
    #   `@config.plugins.plugins`?
    # @return [Boolean] Was the connection successful?
    def start(plugins = true)
      @last_connection_was_successful = false

      @reconnects = 0
      @plugins.register_plugins(@config.plugins.plugins) if plugins

      @user_list.each do |user|
        user.in_whois = false
        user.unsync_all
      end # reset state of all users

      @channel_list.each do |channel|
        channel.unsync_all
      end # reset state of all channels

      @channels = [] # reset list of channels the bot is in

      @join_handler.unregister if @join_handler
      @join_timer.stop if @join_timer

      join_lambda = lambda { @config.channels.each { |channel| Channel(channel).join }}

      if @config.delay_joins.is_a?(Symbol)
        @join_handler = join_handler = on(@config.delay_joins) {
          join_handler.unregister
          join_lambda.call
        }
      else
        @join_timer = Cinch::Timer.new(self, interval: @config.delay_joins, shots: 1) {
          join_lambda.call
        }
      end

      @modes = []

      @loggers.info "Connecting to #{@config.server}:#{@config.port}"
      @irc = MyCinchIRC.new(self)
      @irc.start

      return @last_connection_was_successful
    end
  end

  class MyCinchIRC < Cinch::IRC
    # @api private
    # @return [Boolean] True if the connection could be established
    def connect
      tcp_socket = nil
      @bot.last_connection_exception = nil

      begin
        Timeout::timeout(@bot.config.timeouts.connect) do
          tcp_socket = TCPSocket.new(@bot.config.server, @bot.config.port, @bot.config.local_host)
        end
      rescue Timeout::Error => e
        @bot.last_connection_exception = e
        @bot.loggers.warn("Timed out while connecting")
      rescue SocketError => e
        # エンコーディングがASCII-8BITになって文字化けする場合があるため、
        # Encoding.default_externalに変換する
        e.message.force_encoding(Encoding.default_external)

        @bot.last_connection_exception = e
        @bot.loggers.warn("Could not connect to the IRC server. Please check your network: #{e.message}")
      rescue => e
        @bot.last_connection_exception = e
        @bot.loggers.exception(e)
      end

      return false if @bot.last_connection_exception

      if @bot.config.ssl.use
        setup_ssl(tcp_socket)
      else
        @socket = tcp_socket
      end

      @socket              = Net::BufferedIO.new(@socket)
      @socket.read_timeout = @bot.config.timeouts.read
      @queue               = Cinch::MessageQueue.new(@socket, @bot)

      return true
    end
  end
end

module Cinch
  class Logger
    def log(messages, event = :debug, level = event)
      return unless will_log?(level)
      @mutex.synchronize do
        Array(messages).each do |message|
          message = format_general(message)
          message = format_message(message, event)

          next if message.nil?
          @output.puts message.encode("locale", invalid: :replace, undef: :replace)
        end
      end
    end
  end

  module Utilities
    module Encoding
      def self.encode_incoming(string, encoding)
        string = string.dup
        if encoding == :irc
          string.force_encoding("UTF-8")
          if !string.valid_encoding?
            string.force_encoding("CP1252").encode!("UTF-8", invalid: :replace, undef: :replace)
          end
        else
          string.force_encoding(encoding).encode!("UTF-8", invalid: :replace, undef: :replace)
          string = string.chars.select { |c| c.valid_encoding? }.join
        end

        return string
      end

      def self.encode_outgoing(string, encoding)
        string = string.dup
        if encoding == :irc
          encoding = "UTF-8"
        end

        return string.encode!(encoding, invalid: :replace, undef: :replace).force_encoding("ASCII-8BIT")
      end
    end
  end
end
