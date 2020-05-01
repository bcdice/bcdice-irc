# frozen_string_literal: true

require 'cinch'

module BCDiceIRC
  class MyCinchBot < Cinch::Bot
    attr_accessor :last_connection_error

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

      begin
        Timeout::timeout(@bot.config.timeouts.connect) do
          tcp_socket = TCPSocket.new(@bot.config.server, @bot.config.port, @bot.config.local_host)
        end
      rescue Timeout::Error => e
        @bot.last_connection_error = e
        @bot.loggers.warn("Timed out while connecting")
        return false
      rescue SocketError => e
        @bot.last_connection_error = e
        @bot.loggers.warn("Could not connect to the IRC server. Please check your network: #{e.message}")
        return false
      rescue => e
        @bot.last_connection_error = e
        @bot.loggers.exception(e)
        return false
      end

      if @bot.config.ssl.use
        setup_ssl(tcp_socket)
      else
        @socket = tcp_socket
      end

      @socket              = Net::BufferedIO.new(@socket)
      @socket.read_timeout = @bot.config.timeouts.read
      @queue               = Cinch::MessageQueue.new(@socket, @bot)

      @bot.last_connection_error = nil

      return true
    end
  end
end
