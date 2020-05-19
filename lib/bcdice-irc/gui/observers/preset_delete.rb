# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module Observers
      # プリセット削除のオブザーバを格納するモジュール
      module PresetDelete
        module_function

        # プリセットコンボボックスから項目を削除する
        # @param [Gtk::ComboBox] combo_box
        # @return [Proc]
        def preset_combo_box_remove_item(combo_box)
          lambda do |_config, index|
            combo_box.remove(index)
          end
        end

        # プリセットエントリーの内容を空にする
        # @param [Gtk::Entry] entry
        # @return [Proc]
        def preset_entry_clear(entry)
          lambda do |_config, _index|
            entry.text = ''
          end
        end
      end
    end
  end
end
