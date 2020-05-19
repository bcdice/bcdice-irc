# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module Observers
      # プリセットの保存について実行可能なアクションのオブザーバを格納する
      # モジュール
      module PresetSaveAction
        module_function

        # プリセット保存ボタンのオブザーバを返す
        # @param [Gtk::Button] button
        # @return [Proc]
        def preset_save_button(button)
          lambda do |action|
            button.sensitive = action != :none
            button.label = action == :update ? '更新' : '保存'
          end
        end
      end
    end
  end
end
