# frozen_string_literal: true

require_relative 'test_helper'

module BCDiceIRC
  class IRCBot
    class EncodingInfoTest < Test::Unit::TestCase
      INFO_ISO_2022_JP = EncodingInfo.new(Encoding::ISO_2022_JP, 'ISO-2022-JP', 'Japanese')
      INFO_UTF_8 = EncodingInfo.new(Encoding::UTF_8, 'UTF-8', 'Unicode')

      data('ISO-2022-JP', [INFO_ISO_2022_JP, 'ISO-2022-JP (Japanese)'])
      data('UTF-8', [INFO_UTF_8, 'UTF-8 (Unicode)'])
      test 'to_s' do
        info, expected = data
        assert_equal(expected, info.to_s)
      end
    end
  end
end
