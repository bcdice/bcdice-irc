# frozen_string_literal: true

require 'active_support/core_ext/hash/keys'

require_relative 'encoding_info'

module BCDiceIRC
  IRCBotConfig = Struct.new(
    :name,
    :hostname,
    :port,
    :password,
    :encoding,
    :nick,
    :channel,
    :quit_message,
    :game_system_id,
    keyword_init: true
  )

  # IRCボットの設定の構造体
  class IRCBotConfig
    # @!attribute name
    #   @return [String] 設定の名前
    # @!attribute hostname
    #   @return [String] 接続先のホスト名
    # @!attribute port
    #   @return [Integer] 接続先のポート
    # @!attribute password
    #   @return [String, nil] 接続時に使用するパスワード
    # @!attribute encoding
    #   @return [EncodingInfo] IRCサーバの文字エンコーディング情報
    # @!attribute nick
    #   @return [String] ニックネーム
    # @!attribute channel
    #   @return [String] 最初にJOINするチャンネル
    # @!attribute quit_message
    #   @return [String] QUIT時に送信するメッセージ
    # @!attribute game_system_id
    #   @return [String] ゲームシステムID

    # 既定の設定
    # @return [IRCBotConfig]
    DEFAULT = new(
      name: 'デフォルト',
      hostname: 'irc.trpg.net',
      port: 6667,
      password: nil,
      encoding: NAME_TO_ENCODING['UTF-8'],
      nick: 'BCDice',
      channel: '#Dice_Test',
      quit_message: 'さようなら',
      game_system_id: 'DiceBot'
    ).freeze

    # ハッシュから構造体を構築する
    # @param [Hash] hash 設定の情報が格納されたハッシュ
    # @return [IRCBotConfig]
    def self.from_hash(hash)
      hash_with_sym_keys = hash.symbolize_keys
      new(
        name: hash_with_sym_keys[:name],
        hostname: hash_with_sym_keys[:hostname],
        port: hash_with_sym_keys[:port],
        password: hash_with_sym_keys[:password],
        encoding: NAME_TO_ENCODING.fetch(hash_with_sym_keys[:encoding]),
        nick: hash_with_sym_keys[:nick],
        channel: hash_with_sym_keys[:channel],
        quit_message: hash_with_sym_keys[:quit_message],
        game_system_id: hash_with_sym_keys[:game_system_id]
      )
    end

    # ハッシュに変換する
    # @return [Hash]
    def to_h
      hash = super
      hash[:encoding] = encoding.name

      hash
    end

    # 接続先のエンドポイント（`ホスト名:ポート`）を返す
    # @return [String]
    def end_point
      "#{hostname}:#{port}"
    end
  end
end
