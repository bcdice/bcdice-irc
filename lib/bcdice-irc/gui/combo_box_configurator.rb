# frozen_string_literal: true

require 'gtk3'

module BCDiceIRC
  module GUI
    # コンボボックスの設定を担当するクラス
    class ComboBoxConfigurator
      # 既定の文字列化手続き
      # @return [Proc]
      DEFAULT_STRINGIFY_PROC = :to_s.to_proc

      # @param [Gtk::ComboBox] combo_box 設定対象のコンボボックス
      def initialize(combo_box)
        @combo_box = combo_box
      end

      # コンボボックスに一覧を結び付ける
      #
      # モデルの列0に要素を、列1に文字列を設定する。
      #
      # ブロックとして要素を文字列化する手続きを与える。
      # ブロックが与えられていなければ、+#to_s+ で要素を文字列化する。
      #
      # @param [Enumerable] list 結び付けるEnumerableオブジェクト
      # @param [Proc] stringify 文字列化手続き
      # @yieldparam e [Object] 列挙される要素
      # @yieldreturn [String] 項目として表示する文字列
      # @return [self]
      def bind(list, &stringify)
        stringify ||= DEFAULT_STRINGIFY_PROC
        store = Gtk::ListStore.new(Object, String)

        list.each do |e|
          row = store.append
          row[0] = e
          row[1] = stringify[e]
        end

        @combo_box.model = store

        self
      end

      # コンボボックスの各行の文字列描画を設定する
      # @return [self]
      # @note モデルの列1に表示したい文字列を設定すること。
      def set_cell_renderer_text
        renderer = Gtk::CellRendererText.new
        @combo_box.pack_start(renderer, true)
        @combo_box.add_attribute(renderer, 'text', 1)

        self
      end
    end
  end
end
