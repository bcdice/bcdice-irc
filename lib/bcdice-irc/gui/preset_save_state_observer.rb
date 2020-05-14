# frozen_string_literal: true

module BCDiceIRC
  module GUI
    # プリセットの保存に関する状態についてのオブザーバを格納する
    # モジュール
    module PresetSaveStateObserver
      module_function

      def preset_save_button(button)
        lambda do |state|
          button.label = state.preset_save_button_label
          button.sensitive = state.preset_save_button_sensitive
        end
      end
    end
  end
end
