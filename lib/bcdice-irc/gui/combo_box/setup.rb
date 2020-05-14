# frozen_string_literal: true

require 'gtk3'

module BCDiceIRC
  module GUI
    module ComboBox
      # コンボボックスの設定メソッドを格納するモジュール
      module Setup
        # 既定の文字列化手続き
        # @return [Proc]
        DEFAULT_STRINGIFY_PROC = :to_s.to_proc

        module_function

        # コンボボックスに一覧を結び付ける
        #
        # モデルの列0に要素を、列1に文字列を設定する。
        #
        # ブロックとして要素を文字列化する手続きを与える。
        # ブロックが与えられていなければ、+#to_s+ で要素を文字列化する。
        #
        # @param [Gtk::ComboBox] combo_box 対象のコンボボックス
        # @param [Enumerable] list 結び付けるEnumerableオブジェクト
        # @param [Proc] stringify 文字列化手続き
        # @yieldparam e [Object] 列挙される要素
        # @yieldreturn [String] 項目として表示する文字列
        # @return [Gtk::ComboBox] combo_box
        def bind(combo_box, list, &stringify)
          stringify ||= DEFAULT_STRINGIFY_PROC
          store = Gtk::ListStore.new(Object, String)

          list.each do |e|
            row = store.append
            row[0] = e
            row[1] = stringify[e]
          end

          combo_box.model = store

          combo_box
        end

        # コンボボックスの各行の文字列描画を設定する
        # @param [Gtk::ComboBox] combo_box 対象のコンボボックス
        # @return [Gtk::ComboBox] combo_box
        # @note モデルの列1に表示したい文字列を設定すること。
        def set_cell_renderer_text(combo_box)
          renderer = Gtk::CellRendererText.new
          combo_box.pack_start(renderer, true)
          combo_box.add_attribute(renderer, 'text', 1)

          combo_box
        end
      end
    end
  end
end
