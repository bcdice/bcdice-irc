# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module Observers
      # プリセットを削除できるかについてのオブザーバを格納するモジュール
      module PresetDeletability
        module_function

        # プリセット削除ボタンのオブザーバを返す
        # @param [Gtk::Button] button
        # @return [Proc]
        def preset_delete_button(button)
          lambda do |can_delete_preset|
            button.sensitive = can_delete_preset
          end
        end
      end
    end
  end
end
