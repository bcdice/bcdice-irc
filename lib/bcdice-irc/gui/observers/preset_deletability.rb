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
          lambda do |preset_deletable|
            button.sensitive = preset_deletable
          end
        end
      end
    end
  end
end
