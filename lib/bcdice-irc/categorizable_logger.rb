# frozen_string_literal: true

require 'cinch/logger/formatted_logger'

module BCDiceIRC
  # カテゴリ分けが可能なロガー
  class CategorizableLogger < Cinch::Logger::FormattedLogger
    SPACE = ' '
    PRE_MSG_SEPARATOR = ' :'

    DEBUG_SYMBOL = '!!'
    INFO_SYMBOL = 'II'
    INCOMING_SYMBOL = '>>'
    OUTGOING_SYMBOL = '<<'

    # ログのカテゴリ
    # @return [String]
    attr_reader :category

    # ロガーを初期化する
    # @param [String] category ログのカテゴリ
    # @param [IO] output ログの出力先
    def initialize(category, output, level: :debug)
      super(output, level: level)

      raise ArgumentError, 'no category' if !category || category.empty?

      @category = category
      @formatted_category = "<#{category}>"

      @colorized_debug_symbol = colorize(DEBUG_SYMBOL, :yellow)
      @colorized_incoming_symbol = colorize(INCOMING_SYMBOL, :green)
      @colorized_outgoing_symbol = colorize(OUTGOING_SYMBOL, :red)
      @colorized_exception_symbol = colorize(DEBUG_SYMBOL, :red)
    end

    private

    def join_parts(parts)
      parts.flatten.join(SPACE)
    end

    def format_debug(message)
      parts = [
        timestamp,
        @colorized_debug_symbol,
        @formatted_category,
        message,
      ]

      join_parts(parts)
    end

    def format_info(message)
      parts = [
        timestamp,
        INFO_SYMBOL,
        @formatted_category,
        message,
      ]

      join_parts(parts)
    end

    def split_to_pre_parts_and_msg(message)
      pre, msg = message.split(PRE_MSG_SEPARATOR, 2)
      pre_parts = pre.split(SPACE)

      [pre_parts, msg]
    end

    def format_irc_message(message)
      message ? colorize(":#{message}", :yellow) : nil
    end

    def format_incoming(message)
      pre_parts, msg = split_to_pre_parts_and_msg(message)

      if pre_parts.size == 1
        pre_parts[0] = colorize(pre_parts[0], :bold)
      else
        pre_parts[0] = colorize(pre_parts[0], :blue)
        pre_parts[1] = colorize(pre_parts[1], :bold)
      end

      parts = [
        timestamp,
        @colorized_incoming_symbol,
        @formatted_category,
        pre_parts,
        format_irc_message(msg),
      ]

      join_parts(parts)
    end

    def format_outgoing(message)
      pre_parts, msg = split_to_pre_parts_and_msg(message)

      pre_parts[0] = colorize(pre_parts[0], :bold)

      parts = [
        timestamp,
        @colorized_outgoing_symbol,
        @formatted_category,
        pre_parts,
        format_irc_message(msg),
      ]

      join_parts(parts)
    end

    def format_exception(message)
      parts = [
        timestamp,
        @colorized_exception_symbol,
        @formatted_category,
        message,
      ]

      join_parts(parts)
    end
  end
end
