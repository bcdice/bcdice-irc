# frozen_string_literal: true

module BCDiceIRC
  EncodingInfo = Struct.new(:encoding, :name, :language)

  # BCDice IRCで使う文字エンコーディング情報の構造体
  #
  # `name` は `encoding.name` と同じだが、環境変化で変化しないように明示的に
  # 設定する。
  class EncodingInfo
    # @!attribute encoding
    #   @return [Encoding] 文字エンコーディング
    # @!attribute name
    #   @return [String] 文字エンコーディング名
    # @!attribute language
    #   @return [String] 文字エンコーディングの対象言語

    # 名前と言語を含む文字列に変換する
    # @return [String]
    def to_s
      "#{name} (#{language})"
    end
  end

  # 利用可能な文字エンコーディング情報の配列
  # @return [Array<EncodingInfo>]
  AVAILABLE_ENCODINGS = [
    EncodingInfo.new(Encoding::UTF_8, 'UTF-8', 'Unicode'),
    EncodingInfo.new(Encoding::Windows_1252, 'Windows-1252', 'Latin'),
    EncodingInfo.new(Encoding::ISO_8859_15, 'ISO-8859-15', 'Latin'),
    EncodingInfo.new(Encoding::ISO_2022_JP, 'ISO-2022-JP', 'Japanese'),
    EncodingInfo.new(Encoding::CP949, 'CP949', 'Korean'),
    EncodingInfo.new(Encoding::GBK, 'GBK', 'Simplified Chinese'),
    EncodingInfo.new(Encoding::GB18030, 'GB18030', 'Simplified Chinese'),
    EncodingInfo.new(Encoding::Big5, 'Big5', 'Traditional Chinese'),
  ].map(&:freeze).freeze

  # 文字エンコーディング名と文字エンコーディング情報との対応
  # @return [Hash<String, EncodingInfo>]
  NAME_TO_ENCODING = AVAILABLE_ENCODINGS
                     .map { |e| [e.name, e] }
                     .to_h
                     .freeze
end
