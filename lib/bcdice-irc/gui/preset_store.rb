# frozen_string_literal: true

require 'forwardable'
require 'yaml'

require 'active_support/core_ext/hash/keys'

require_relative '../irc_bot/config'

module BCDiceIRC
  module GUI
    # プリセットの管理を担当するクラス
    class PresetStore
      include Enumerable
      extend Forwardable

      # 最後に選択されたプリセットのインデックス
      #
      # `-1` の場合、プリセット未選択状態を表す。
      #
      # @return [Integer]
      attr_reader :index_last_selected

      # ロガー
      # @return [Cinch::Logger]
      attr_accessor :logger

      def_delegators(
        :@presets,
        :length,
        :size,
        :empty?
      )

      # 番号からプリセットを取得する
      # @!method fetch(index)
      #   @param [Integer] index プリセット番号（0-indexed）
      #   @return [IRCBot::Config]
      #   @raise [IndexError] 指定された番号の要素が存在しなかった場合
      def_delegator(:@presets, :fetch, :fetch_by_index)

      def_delegators(
        :@name_index_preset_map,
        :include?,
        :member?
      )

      # 既定のプリセット集を返す
      # @return [PresetStore]
      def self.default
        store = new
        store.push(IRCBot::Config::DEFAULT)
        store
      end

      # 初期化する
      def initialize
        clear
        @logger = nil
      end

      # 各プリセットに対して処理を行う
      # @yieldparam [IRCBot::Config] config 各プリセット
      def each(&b)
        @presets.each(&b)
      end

      # プリセットをすべて削除する
      # @return [self]
      def clear
        @index_last_selected = nil
        @presets = []
        @name_index_preset_map = {}

        self
      end

      # 複数のプリセットがあるかを返す
      # @return [Boolean]
      def have_multiple_presets?
        length > 1
      end

      # 最後に選択されたプリセットの番号を設定する
      #
      # `value` に `-1` を設定すると、未選択状態を表す。
      #
      # @param [Integer] value プリセット番号
      # @raise [RangeError] `value` が `-2` 以下か、プリセット数以上だった場合
      def index_last_selected=(value)
        valid_range = -1...length
        unless valid_range.include?(value)
          raise RangeError, "index_last_selected must be in #{valid_range}"
        end

        @index_last_selected = value
      end

      # プリセットを追加する
      # @param [IRCBot::Config] config IRCボット設定
      # @return [Symbol] 追加された（`:appended`）か更新された（`:updated`）か
      def push(config)
        need_append = !include?(config.name)

        if need_append
          append(config, empty?)
        else
          update(config)
        end
      end

      # プリセットを削除する
      # @param [String] name 削除するプリセットの名前
      # @return [Integer] 削除したプリセットの番号（見つからなかった場合は `-1`）
      # @note 最後の1個は消すことができない（`-1` を返す）。
      def delete(name)
        return -1 unless have_multiple_presets?

        index, = @name_index_preset_map[name]
        return -1 unless index

        @presets.delete_at(index)
        @name_index_preset_map.delete(name)

        self.index_last_selected = -1

        index
      end

      # 名前でプリセットを取り出す
      # @param [String] name プリセット名
      # @return [IRCBot::Config]
      def fetch_by_name(name)
        _, config = @name_index_preset_map.fetch(name)
        config
      end

      # ハッシュからプリセット集を作る
      # @param [Hash] hash
      # @return [self]
      def from_hash(hash)
        clear

        hash_with_sym_keys = hash.symbolize_keys

        hash_with_sym_keys[:presets]&.each do |h|
          begin
            config = IRCBot::Config.from_hash(h)
            push(config)
          rescue => e
            @logger&.warn('IRCBot::Config.from_hash failed')
            @logger&.exception(e)
          end
        end

        begin
          self.index_last_selected = hash_with_sym_keys[:index_last_selected]
        rescue => e
          @index_last_selected = empty? ? nil : 0
          @logger&.warn("index_last_selected setting failed, set #{@index_last_selected.inspect}")
          @logger&.exception(e)
        end

        self
      end

      # ハッシュに変換する
      # @return [Hash]
      def to_h
        {
          index_last_selected: @index_last_selected,
          presets: @presets.map(&:to_h)
        }
      end

      # YAMLファイルを読み込んでプリセット集を作る
      # @param [String] yaml_path YAMLファイルのパス
      # @return [self]
      def load_yaml_file(yaml_path)
        o = YAML.load_file(yaml_path)
        from_hash(o)

        self
      end

      # プリセット集をYAMLファイルに書き出す
      # @param [String] yaml_path YAMLファイルのパス
      # @return [self]
      def write_yaml_file(yaml_path)
        File.open(yaml_path, 'w') do |f|
          YAML.dump(to_h.deep_stringify_keys, f)
        end

        self
      end

      private

      # プリセットを末尾に追加する
      # @param [IRCBot::Config] config IRCボットの設定
      # @param [Boolean] empty_before_append 追加前に空だったか
      # @return [Symbol] `:appended`
      def append(config, empty_before_append)
        new_index = length
        @presets.push(config)
        @name_index_preset_map[config.name] = [new_index, config]

        self.index_last_selected = new_index

        :appended
      end

      # 記録されているプリセットを更新する
      # @param [IRCBot::Config] config IRCボットの設定
      # @return [Symbol] `:updated`
      def update(config)
        index, = @name_index_preset_map[config.name]
        @presets[index] = config
        @name_index_preset_map[config.name] = [index, config]
        self.index_last_selected = index

        :updated
      end
    end
  end
end
