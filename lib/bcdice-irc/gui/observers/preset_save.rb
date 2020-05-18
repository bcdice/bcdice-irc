# frozen_string_literal: true

module BCDiceIRC
  module GUI
    module Observers
      # プリセット追加/更新のオブザーバを格納するモジュール
      module PresetSave
        module_function

        # プリセットコンボボックスに項目を追加する
        # @param [Gtk::ComboBox] combo_box
        # @return [Proc]
        def preset_combo_box_append_item(combo_box)
          lambda do |config, _index|
            combo_box.append_text(config.name)
          end
        end

        # プリセットコンボボックスのアクティブな項目を変更する
        # @param [Gtk::ComboBox] combo_box
        # @param [Integer] on_changed_handler_id
        # @return [Proc]
        def preset_combo_box_active(combo_box, on_changed_handler_id)
          lambda do |_config, index|
            combo_box.signal_handler_block(on_changed_handler_id) do
              combo_box.active = index
            end
          end
        end
      end
    end
  end
end
