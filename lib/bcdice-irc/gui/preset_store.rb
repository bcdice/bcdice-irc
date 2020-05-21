# frozen_string_literal: true

require 'forwardable'
require 'yaml'

require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/object/blank'

require_relative '../irc_bot_config'

module BCDiceIRC
  module GUI
    # プリセットの管理を担当するクラス。
    #
    # プリセット集および最後に選択されていたプリセットの番号の管理を行う。
    # プリセット集の管理については、プリセットの追加（起動時の設定ファイルから
    # の読み込みも含む）、保存（追加）、更新、削除が行える。
    # 最後に選択されていたプリセットの番号は、次回起動時にその設定を自動的に
    # 読み込むために使う。
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

      # @!method each
      #   各プリセットに対して処理を行う
      #   @yieldparam [IRCBotConfig] config 各プリセット
      # @!method length
      #   格納しているプリセットの数を返す
      #   @return [Integer]
      # @!method empty?
      #   格納しているプリセットが存在しないかを返す
      #   @return [Boolean]
      def_delegators(
        :@presets,
        :each,
        :length,
        :size,
        :empty?
      )

      # @!method fetch(index)
      #   番号からプリセットを取得する
      #   @param [Integer] index プリセット番号（0-indexed）
      #   @return [IRCBotConfig]
      #   @raise [IndexError] 指定された番号の要素が存在しなかった場合
      def_delegator(:@presets, :fetch, :fetch_by_index)

      # @!method include?(name)
      #   指定した名前のプリセットが存在するかを返す
      #   @param [String] name プリセット名
      #   @return [Boolean]
      def_delegators(
        :@name_index_preset_map,
        :include?,
        :member?
      )

      def initialize
        clear

        @logger = nil
      end

      # プリセットをすべて削除する
      # @return [self]
      def clear
        @index_last_selected = -1
        @presets = []
        @name_index_preset_map = {}

        self
      end

      # 複数のプリセットがあるかを返す
      # @return [Boolean]
      def multiple_presets?
        length > 1
      end

      # 指定された名前のプリセットの保存について、実行可能なアクションを返す
      # @param [String] preset_name プリセット名
      # @return [:none] プリセットの保存が不可能な場合
      # @return [:append] プリセットの追加が可能な場合
      # @return [:update] プリセットの更新が可能な場合
      def preset_save_action(preset_name)
        if include?(preset_name)
          :update
        elsif preset_name.blank?
          :none
        else
          :append
        end
      end

      # 指定された名前のプリセットの削除が可能かを返す
      # @param [String] preset_name プリセット名
      # @return [Boolean]
      def can_delete_preset?(preset_name)
        multiple_presets? && include?(preset_name)
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

      # プリセットの追加結果の構造体
      # @!attribute action
      #   @return [:appended] プリセットを追加した場合
      #   @return [:updated] プリセットを更新した場合
      # @!attribute index
      #   @return [Integer] 追加/更新したプリセットの番号
      # @!attribute config
      #   @return [IRCBotConfig] 追加/更新したIRCボット設定
      PushResult = Struct.new(
        :action,
        :index,
        :config,
        keyword_init: true
      )

      # プリセットを追加する
      # @param [IRCBotConfig] config IRCボット設定
      # @return [PushResult]
      def push(config)
        need_append = !include?(config.name)

        if need_append
          append(config)
        else
          update(config)
        end
      end

      # プリセットの削除結果の構造体
      # @!attribute deleted
      #   @return [Boolean] プリセットを削除したか
      # @!attribute index
      #   @return [Integer] 削除したプリセットの番号
      # @!attribute config
      #   @return [IRCBotConfig] 削除したIRCボット設定
      DeleteResult = Struct.new(
        :deleted,
        :index,
        :config,
        keyword_init: true
      )

      # 削除しなかったことを示す結果
      DID_NOT_DELETE = DeleteResult.new(
        deleted: false,
        index: -1,
        config: nil
      ).freeze

      # プリセットを削除する
      # @param [String] name 削除するプリセットの名前
      # @return [Integer] 削除したプリセットの番号（見つからなかった場合は `-1`）
      # @note 最後の1個は消すことができない（`-1` を返す）。
      def delete(name)
        return DID_NOT_DELETE unless multiple_presets?

        index, = @name_index_preset_map[name]
        return DID_NOT_DELETE unless index

        config = @presets.delete_at(index)
        rebuild_name_index_preset_map

        self.index_last_selected = -1

        DeleteResult.new(
          deleted: true,
          index: index,
          config: config
        )
      end

      # 名前でプリセットを取り出す
      # @param [String] name プリセット名
      # @return [IRCBotConfig]
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
          config = IRCBotConfig.from_hash(h)
          push(config)
        rescue => e
          @logger&.warn('IRCBotConfig.from_hash failed')
          @logger&.exception(e)
        end

        begin
          self.index_last_selected = hash_with_sym_keys[:index_last_selected]
        rescue => e
          @index_last_selected = empty? ? -1 : 0
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
          presets: @presets.map(&:to_h),
        }
      end

      # 既定のプリセット集を読み込む
      # @return [PresetStore]
      def load_default
        clear
        push(IRCBotConfig::DEFAULT)
        self.index_last_selected = 0

        self
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
      # @param [IRCBotConfig] config IRCボットの設定
      # @return [Symbol] `:appended`
      def append(config)
        new_index = length
        @presets.push(config)
        @name_index_preset_map[config.name] = [new_index, config]

        PushResult.new(action: :appended, index: new_index, config: config)
      end

      # 記録されているプリセットを更新する
      # @param [IRCBotConfig] config IRCボットの設定
      # @return [Symbol] `:updated`
      def update(config)
        index, = @name_index_preset_map[config.name]
        @presets[index] = config
        @name_index_preset_map[config.name] = [index, config]

        PushResult.new(action: :updated, index: index, config: config)
      end

      # プリセット名→番号および設定のHashを再構築する
      # @return [self]
      def rebuild_name_index_preset_map
        @name_index_preset_map =
          @presets
          .each_with_index
          .map { |config, index| [config.name, [index, config]] }
          .to_h

        self
      end
    end
  end
end
