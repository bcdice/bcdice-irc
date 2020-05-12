# frozen_string_literal: true

module BCDiceIRC
  module GUI
    # プリセットの保存に関する状態の構造体
    PresetSaveState = Struct.new(
      :name,
      :preset_save_button_label,
      :preset_save_button_sensitive,
      keyword_init: true
    )

    class PresetSaveState
      # 同名のプリセットが存在している
      PRESET_EXISTS = new(
        name: 'preset exists',
        preset_save_button_label: '更新',
        preset_save_button_sensitive: true
      )

      # プリセット名として無効な名前が設定されている
      INVALID_NAME = new(
        name: 'invalid name',
        preset_save_button_label: '保存',
        preset_save_button_sensitive: false
      )

      # 新しいプリセットとして保存できる
      NEW_PRESET = new(
        name: 'new preset',
        preset_save_button_label: '保存',
        preset_save_button_sensitive: true
      )
    end
  end
end
