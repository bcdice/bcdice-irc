# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module Observers
      # プリセットの保存に関する状態についてのオブザーバを格納する
      # モジュール
      module PresetSaveState
        module_function

        # プリセット保存ボタンのオブザーバを返す
        # @param [Gtk::Button] button
        # @return [Proc]
        def preset_save_button(button)
          lambda do |state|
            button.label = state.preset_save_button_label
            button.sensitive = state.preset_save_button_sensitive
          end
        end
      end
    end
  end
end
