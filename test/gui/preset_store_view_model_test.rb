# frozen_string_literal: true

require_relative '../test_helper'

require 'active_support/core_ext/object/deep_dup'

require 'bcdice-irc/gui/preset_store'
require 'bcdice-irc/gui/preset_store_view_model'

module BCDiceIRC
  module GUI
    class PresetStoreViewModelTest < Test::Unit::TestCase
      setup do
        @store = PresetStore.new
        @view_model = PresetStoreViewModel.new(@store)

        @config1 = IRCBotConfig.new(
          name: 'デフォルト',
          hostname: 'irc.trpg.net',
          port: 6667,
          password: nil,
          encoding: NAME_TO_ENCODING['UTF-8'],
          nick: 'BCDice',
          channel: '#Dice_Test',
          quit_message: 'さようなら',
          game_system_id: 'DiceBot'
        ).freeze

        @config2 = IRCBotConfig.new(
          name: 'Config 1',
          hostname: 'irc.example.net',
          port: 6664,
          password: 'p@ssw0rd',
          encoding: NAME_TO_ENCODING['ISO-2022-JP'],
          nick: 'DiceBot',
          channel: '#DiceTest',
          quit_message: 'Bye',
          game_system_id: 'DiceBot'
        ).freeze
      end

      data('空文字列', ['', false, 'Save'])
      data('空白のみ', [' 　', false, 'Save'])
      data('既存1', ['デフォルト', true, 'Update'])
      data('新規', ['Config 2', true, 'Save'])
      test 'preset_save_action_updated handlers should be called after setting temporary_preset_name' do |data|
        temporary_preset_name, expected_sensitive, expected_label = data

        @store.push(@config1)

        preset_save_button_sensitive = nil
        preset_save_button_label = nil

        @view_model.add_preset_save_action_updated_handlers(
          ->action { preset_save_button_sensitive = action != :none },
          lambda do |action|
            preset_save_button_label = action == :update ? 'Update' : 'Save'
          end
        )

        @view_model.temporary_preset_name = temporary_preset_name

        assert_equal(expected_sensitive, preset_save_button_sensitive)
        assert_equal(expected_label, preset_save_button_label)
      end

      data('空文字列', ['', false])
      data('空白のみ', [' 　', false])
      data('既存1', ['デフォルト', true])
      data('既存2', ['Config 1', true])
      data('新規', ['Config 2', false])
      test 'preset_deletability_updated handlers should be called after setting temporary_preset_name' do |data|
        temporary_preset_name, expected_sensitive = data

        @store.push(@config1)
        @store.push(@config2)

        preset_delete_button_sensitive = nil

        @view_model.add_preset_deletability_updated_handlers(
          ->can_delete_preset { preset_delete_button_sensitive = can_delete_preset }
        )

        @view_model.temporary_preset_name = temporary_preset_name

        assert_equal(expected_sensitive, preset_delete_button_sensitive)
      end

      test '#preset_names' do
        @store.push(@config1)
        @store.push(@config2)

        assert_equal(['デフォルト', 'Config 1'], @view_model.preset_names)
      end

      test '#load_by_index should update attributes correctly' do
        @store.push(@config1)
        @store.push(@config2)

        assert_true(@view_model.load_by_index(0))

        assert_equal(0, @view_model.index_last_selected)
        assert_equal('デフォルト', @view_model.temporary_preset_name)
      end

      test '#load_by_index should call registered preset_load handlers' do
        @store.push(@config1)
        @store.push(@config2)

        preset_index = nil
        preset_name = nil

        @view_model.add_preset_load_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        @view_model.load_by_index(0)

        assert_equal(0, preset_index)
        assert_equal('デフォルト', preset_name)
      end

      test '#load_by_index(-1) should do nothing' do
        @store.push(@config1)
        @store.push(@config2)

        preset_index = nil
        preset_name = nil

        @view_model.add_preset_load_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        assert_false(@view_model.load_by_index(-1))

        assert_equal(-1, @view_model.index_last_selected)
        assert_nil(preset_index)
        assert_nil(preset_name)
      end

      test 'save new preset' do
        @store.push(@config1)

        @view_model.temporary_preset_name = @config2.name.dup
        result = @view_model.save(@config2)

        assert_equal(:appended, result.action)
        assert_equal(1, result.index)

        assert_equal(2, @view_model.length)
        assert_equal(1, @view_model.index_last_selected)
        assert_equal('Config 1', @view_model.temporary_preset_name)
        assert_equal(:update, @view_model.preset_save_action)
        assert_equal(true, @view_model.can_delete_preset?)
      end

      test 'registered preset_append handlers should be called after saving new preset' do
        @store.push(@config1)

        preset_index = nil
        preset_name = nil

        @view_model.add_preset_append_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        @view_model.temporary_preset_name = @config2.name.dup
        @view_model.save(@config2)

        assert_equal(1, preset_index)
        assert_equal('Config 1', preset_name)
      end

      test 'save existing preset' do
        @store.push(@config1)
        @store.push(@config2)

        config1_modified = @config1.deep_dup
        config1_modified.hostname = 'irc2.example.net'

        @view_model.temporary_preset_name = config1_modified.name.dup
        result = @view_model.save(config1_modified)

        assert_equal(:updated, result.action)
        assert_equal(0, result.index)

        assert_equal(2, @view_model.length)
        assert_equal(0, @view_model.index_last_selected)
        assert_equal('デフォルト', @view_model.temporary_preset_name)
        assert_equal(:update, @view_model.preset_save_action)
        assert_equal(true, @view_model.can_delete_preset?)
      end

      test 'registered preset_update handlers should be called after saving existing preset' do
        @store.push(@config1)
        @store.push(@config2)

        preset_index = nil
        preset_name = nil

        @view_model.add_preset_update_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        config1_modified = @config1.deep_dup
        config1_modified.hostname = 'irc2.example.net'

        @view_model.temporary_preset_name = config1_modified.name.dup
        result = @view_model.save(config1_modified)

        assert_equal(0, preset_index)
        assert_equal('デフォルト', preset_name)
      end

      test '#delete' do
        @store.push(@config1)
        @store.push(@config2)
        @store.index_last_selected = 1

        @view_model.temporary_preset_name = 'Config 1'
        result = @view_model.delete('Config 1')

        assert_true(result.deleted)
        assert_equal(1, result.index)
        assert_equal('Config 1', result.config.name)

        assert_equal(1, @view_model.length)
        assert_equal(-1, @view_model.index_last_selected, 'プリセット未選択状態になる')

        assert_equal('', @view_model.temporary_preset_name)
        assert_equal(:none, @view_model.preset_save_action)
        assert_equal(false, @view_model.can_delete_preset?)
      end

      test 'registered preset_delete handlers should be called after deleting preset' do
        @store.push(@config1)
        @store.push(@config2)
        @store.index_last_selected = 1

        preset_index = nil
        preset_name = nil

        @view_model.add_preset_delete_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        @view_model.temporary_preset_name = 'Config 1'
        @view_model.delete('Config 1')

        assert_equal(1, preset_index)
        assert_equal('Config 1', preset_name)
      end

      test 'registered preset_delete handlers should not be called after trying to delete non-existing preset' do
        @store.push(@config1)
        @store.push(@config2)
        @store.index_last_selected = 1

        preset_index = nil
        preset_name = nil

        @view_model.add_preset_delete_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        @view_model.temporary_preset_name = 'Config 2'
        @view_model.delete('Config 2')

        assert_nil(preset_index)
        assert_nil(preset_name)
      end
    end
  end
end
