# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module ComboBox
      # コンボボックスの項目選択処理
      class Activator
        # @param [Gtk::ComboBox] combo_box コンボボックス
        # @param [Enumerable] list 結び付けるリスト
        def initialize(combo_box, list)
          @combo_box = combo_box
          @map_to_index = list.each_with_index.to_h
        end

        # 項目を選択する
        # @param [Object] x 項目
        # @return [Boolean] 指定した項目がアクティブになったか
        def activate(x)
          new_index = @map_to_index[x]
          return false unless new_index

          @combo_box.active = new_index

          true
        end
      end
    end
  end
end
