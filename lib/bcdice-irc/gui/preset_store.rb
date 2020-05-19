# frozen_string_literal: true

require 'forwardable'
require 'yaml'

require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/object/blank'

require_relative '../irc_bot/config'

module BCDiceIRC
  module GUI
    # プリセットの管理を担当するクラス。
    #
    # このクラスは、プリセット集および選択されているプリセットの管理を行う。
    #
    # プリセット集の管理については、プリセットの追加（起動時の設定ファイルから
    # の読み込みも含む）、保存（追加）、更新、削除を行える。
    # GUIの更新のために、プリセットの保存（追加）、更新、削除が行われた後、
    # それぞれに対応するハンドラ（preset_append、preset_update、preset_delete）
    # を実行できるようにしている。
    # また、一時的なプリセット名を設定することができ、その名前でプリセットを
    # 保存/更新可能か、および削除可能かを判断する。
    #
    # 選択されているプリセットの管理については、現在の状態に合わせてコンボ
    # ボックスのアクティブ項目を変更することを想定して、プリセットの追加、
    # 保存、更新、削除といった操作に応じて、選択されているプリセット番号が適切
    # に動くようにしている。
    class PresetStore
      include Enumerable
      extend Forwardable

      # 最後に選択されたプリセットのインデックス
      #
      # `-1` の場合、プリセット未選択状態を表す。
      #
      # @return [Integer]
      attr_reader :index_last_selected

      # 一時的なプリセット名
      #
      # この名前でのプリセットの保存/更新、および削除が可能かを判断する。
      #
      # @return [String]
      attr_reader :temporary_preset_name

      # プリセットの保存について実行可能なアクション
      # @return [:none] プリセットの保存が不可能な場合
      # @return [:append] プリセットの追加が可能な場合
      # @return [:update] プリセットの更新が可能な場合
      attr_reader :preset_save_action

      # ロガー
      # @return [Cinch::Logger]
      attr_accessor :logger

      # @!method each
      #   各プリセットに対して処理を行う
      #   @yieldparam [IRCBot::Config] config 各プリセット
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
      #   @return [IRCBot::Config]
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

        @preset_load_handlers = []
        @preset_append_handlers = []
        @preset_update_handlers = []
        @preset_delete_handlers = []
        @preset_save_action_updated_handlers = []
        @preset_deletability_updated_handlers = []
      end

      # プリセットをすべて削除する
      # @return [self]
      def clear
        @index_last_selected = nil
        @temporary_preset_name = ''
        @presets = []
        @name_index_preset_map = {}

        # プリセットの保存について実行可能なアクション
        # :none、:append、:update のいずれか
        @preset_save_action = :none

        @can_delete_preset = false

        self
      end

      # 複数のプリセットがあるかを返す
      # @return [Boolean]
      def multiple_presets?
        length > 1
      end

      # プリセットの削除が可能かを返す
      # @return [Boolean]
      def can_delete_preset?
        @can_delete_preset
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

      # 一時的なプリセット名を設定する
      #
      # 設定後、その名前でプリセットを保存/更新可能か、および削除可能かを更新する。
      #
      # @param [String] value 一時的なプリセット名
      def temporary_preset_name=(value)
        @temporary_preset_name = value

        update_preset_save_action
        update_preset_deletability
      end

      # プリセットの保存について実行可能なアクションが更新されたときに実行する
      # 手続きを登録する
      # @param [Array<Proc>] handlers 登録する手続き
      # @return [self]
      def add_preset_save_action_updated_handlers(*handlers)
        @preset_save_action_updated_handlers.push(*handlers)
        self
      end

      # プリセットの削除が可能かが更新されたときに実行する手続きを登録する
      # @param [Array<Proc>] handlers 登録する手続き
      # @return [self]
      def add_preset_deletability_updated_handlers(*handlers)
        @preset_deletability_updated_handlers.push(*handlers)
        self
      end

      # プリセットを追加する
      # @param [IRCBot::Config] config IRCボット設定
      # @return [Symbol] 追加された（`:appended`）か更新された（`:updated`）か
      def push(config)
        need_append = !include?(config.name)

        if need_append
          append(config)
        else
          update(config)
        end
      end

      # プリセットを追加したときに実行する手続きを登録する
      # @param [Array<Proc>] handlers 登録する手続き
      # @return [self]
      def add_preset_append_handlers(*handlers)
        @preset_append_handlers.push(*handlers)
        self
      end

      # プリセットを更新したときに実行する手続きを登録する
      # @param [Array<Proc>] handlers 登録する手続き
      # @return [self]
      def add_preset_update_handlers(*handlers)
        @preset_update_handlers.push(*handlers)
        self
      end

      # プリセットを削除する
      # @param [String] name 削除するプリセットの名前
      # @return [Integer] 削除したプリセットの番号（見つからなかった場合は `-1`）
      # @note 最後の1個は消すことができない（`-1` を返す）。
      def delete(name)
        return -1 unless multiple_presets?

        index, = @name_index_preset_map[name]
        return -1 unless index

        config = @presets.delete_at(index)
        @name_index_preset_map.delete(name)

        self.index_last_selected = -1

        @preset_delete_handlers.each do |handler|
          handler[config, index]
        end

        index
      end

      # プリセットを削除したときに実行する手続きを登録する
      # @param [Array<Proc>] handlers 登録する手続き
      # @return [self]
      def add_preset_delete_handlers(*handlers)
        @preset_delete_handlers.push(*handlers)
        self
      end

      # 名前でプリセットを取り出す
      # @param [String] name プリセット名
      # @return [IRCBot::Config]
      def fetch_by_name(name)
        _, config = @name_index_preset_map.fetch(name)
        config
      end

      # 番号で指定したプリセットを読み込む
      #
      # 読み込み完了後、`add_preset_load_handlers` で登録した手続きを実行する。
      #
      # @param [Integer] index プリセット番号
      # @return [self]
      def load_by_index(index)
        return self if index < 0

        config = fetch_by_index(index)
        load_preset(config, index)
      end

      # 名前で指定したプリセットを読み込む
      #
      # 読み込み完了後、`add_preset_load_handlers` で登録した手続きを実行する。
      #
      # @param [String] name プリセット名
      # @return [self]
      def load_by_name(name)
        index, config = @name_index_preset_map.fetch(name)
        load_preset(config, index)
      end

      # プリセットを読み込んだときに実行する手続きを登録する
      # @param [Array<Proc>] handlers 登録する手続き
      # @return [self]
      def add_preset_load_handlers(*handlers)
        @preset_load_handlers.push(*handlers)
        self
      end

      # ハッシュからプリセット集を作る
      # @param [Hash] hash
      # @return [self]
      def from_hash(hash)
        clear

        hash_with_sym_keys = hash.symbolize_keys

        hash_with_sym_keys[:presets]&.each do |h|
          config = IRCBot::Config.from_hash(h)
          push(config)
        rescue => e
          @logger&.warn('IRCBot::Config.from_hash failed')
          @logger&.exception(e)
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
          presets: @presets.map(&:to_h),
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

      # プリセットの保存について実行可能なアクションを更新する
      # @return [self]
      def update_preset_save_action
        @preset_save_action =
          if include?(@temporary_preset_name)
            :update
          elsif @temporary_preset_name.blank?
            :none
          else
            :append
          end

        @preset_save_action_updated_handlers.each do |handler|
          handler[@preset_save_action]
        end

        self
      end

      # プリセットの削除が可能かを更新する
      # @return [self]
      def update_preset_deletability
        @can_delete_preset =
          multiple_presets? && include?(@temporary_preset_name)

        @preset_deletability_updated_handlers.each do |handler|
          handler[@can_delete_preset]
        end

        self
      end

      # プリセットを末尾に追加する
      # @param [IRCBot::Config] config IRCボットの設定
      # @return [Symbol] `:appended`
      def append(config)
        new_index = length
        @presets.push(config)
        @name_index_preset_map[config.name] = [new_index, config]

        self.index_last_selected = new_index

        @preset_append_handlers.each do |handler|
          handler[config, new_index]
        end

        self.temporary_preset_name = config.name

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

        @preset_update_handlers.each do |handler|
          handler[config, index]
        end

        self.temporary_preset_name = config.name

        :updated
      end

      # 指定したプリセットを読み込む（共通処理）
      #
      # 読み込み完了後、`add_preset_load_handlers` で登録した手続きを実行する。
      #
      # @param [IRCBot::Config] config IRCボット設定
      # @param [Integer] index プリセット番号
      # @return [self]
      def load_preset(config, index)
        self.index_last_selected = index
        self.temporary_preset_name = config.name

        @preset_load_handlers.each do |handler|
          handler[config, index]
        end

        self
      end
    end
  end
end
