# frozen_string_literal: true

require 'forwardable'

module BCDiceIRC
  module GUI
    # プリセット集のビューモデル。
    #
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
    class PresetStoreViewModel
      extend Forwardable

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

      # @!method length
      #   格納しているプリセットの数を返す
      #   @return [Integer]
      # @!attribute [r] index_last_selected
      #   最後に選択されたプリセットのインデックス
      #
      #   `-1` の場合、プリセット未選択状態を表す。
      #
      #   @return [Integer]
      def_delegators(
        :@store,
        :length,
        :index_last_selected
      )

      # @param [PresetStore] store プリセット集のモデル
      def initialize(store)
        @store = store

        @temporary_preset_name = ''
        @preset_save_action = :none
        @can_delete_preset = false

        @preset_load_handlers = []
        @preset_append_handlers = []
        @preset_update_handlers = []
        @preset_delete_handlers = []
        @preset_save_action_updated_handlers = []
        @preset_deletability_updated_handlers = []
      end

      # 一時的なプリセット名を設定する
      #
      # 設定後、その名前でプリセットを保存/更新可能か、および削除可能かを更新する。
      #
      # @param [String] value 一時的なプリセット名
      def temporary_preset_name=(value)
        @temporary_preset_name = value

        @preset_save_action = @store.preset_save_action(@temporary_preset_name)
        @can_delete_preset = @store.can_delete_preset?(@temporary_preset_name)

        @preset_save_action_updated_handlers.each do |handler|
          handler[@preset_save_action]
        end

        @preset_deletability_updated_handlers.each do |handler|
          handler[@can_delete_preset]
        end
      end

      # プリセットの削除が可能かを返す
      # @return [Boolean]
      def can_delete_preset?
        @can_delete_preset
      end

      # プリセット名の配列を返す
      # @return [Array<String>]
      def preset_names
        @store.map(&:name)
      end

      # プリセットを読み込んだときに実行する手続きを登録する
      # @param [Array<Proc>] handlers 登録する手続き
      # @return [self]
      def add_preset_load_handlers(*handlers)
        @preset_load_handlers.push(*handlers)
        self
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

      # プリセットを削除したときに実行する手続きを登録する
      # @param [Array<Proc>] handlers 登録する手続き
      # @return [self]
      def add_preset_delete_handlers(*handlers)
        @preset_delete_handlers.push(*handlers)
        self
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

      # 番号で指定したプリセットを読み込む
      #
      # 読み込み完了後、`add_preset_load_handlers` で登録した手続きを実行する。
      #
      # `index` が0未満だった場合は、何もしない。
      #
      # @param [Integer] index プリセット番号
      # @return [true] プリセットを読み込んだ場合
      # @return [false] プリセットを読み込まなかった場合（`index < 0`）
      def load_by_index(index)
        return false if index < 0

        config = @store.fetch_by_index(index)
        @store.index_last_selected = index
        self.temporary_preset_name = config.name

        @preset_load_handlers.each do |handler|
          handler[config, index]
        end

        true
      end

      # プリセットを保存する
      # @param [IRCBotConfig] config IRCボット設定
      # @return (see PresetStore#push)
      def save(config)
        push_result = @store.push(config)

        @store.index_last_selected = push_result.index
        self.temporary_preset_name = push_result.config.name

        handlers =
          case push_result.action
          when :appended
            @preset_append_handlers
          when :updated
            @preset_update_handlers
          else
            []
          end

        handlers.each do |handler|
          handler[push_result.config, push_result.index]
        end

        push_result
      end

      # プリセットを削除する
      # @param [String] preset_name プリセット名
      # @return (see PresetStore#delete)
      def delete(preset_name)
        delete_result = @store.delete(preset_name)
        return unless delete_result.deleted

        self.temporary_preset_name = ''

        @preset_delete_handlers.each do |handler|
          handler[delete_result.config, delete_result.index]
        end

        delete_result
      end
    end
  end
end
