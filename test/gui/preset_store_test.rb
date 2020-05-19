# frozen_string_literal: true

require 'yaml'
require 'fileutils'

require_relative '../test_helper'
require 'bcdice-irc/gui/preset_store'

module BCDiceIRC
  module GUI
    class PresetStoreTest < Test::Unit::TestCase
      # YAMLファイル書き出しテストにおける出力先のパス
      YAML_PATH_TO_WRITE = File.expand_path('write_test.yaml', __dir__)

      setup do
        @store = PresetStore.new

        @config1 = IRCBot::Config.new(
          name: 'デフォルト',
          hostname: 'irc.trpg.net',
          port: 6667,
          password: nil,
          encoding: IRCBot::NAME_TO_ENCODING['UTF-8'],
          nick: 'BCDice',
          channel: '#Dice_Test',
          quit_message: 'さようなら',
          game_system_id: 'DiceBot'
        ).freeze

        @config2 = IRCBot::Config.new(
          name: 'Config 1',
          hostname: 'irc.example.net',
          port: 6664,
          password: 'p@ssw0rd',
          encoding: IRCBot::NAME_TO_ENCODING['ISO-2022-JP'],
          nick: 'DiceBot',
          channel: '#DiceTest',
          quit_message: 'Bye',
          game_system_id: 'DiceBot'
        ).freeze

        @yaml_path = File.expand_path('presets_test_data.yaml', __dir__)
      end

      teardown do
        FileUtils.rm_f(YAML_PATH_TO_WRITE)
      end

      test 'push and length/size/count' do
        @store.push(@config1)
        @store.push(@config2)

        assert_equal(2, @store.length)
        assert_equal(2, @store.size)
        assert_equal(2, @store.count)
      end

      test 'delete' do
        @store.push(@config1)
        @store.push(@config2)
        assert_equal(2, @store.length)

        delete_result = @store.delete('Config 1')
        assert_equal(1, delete_result, '消した項目のインデックスが返る')
        assert_equal(1, @store.length, '個数が1個減る')
        assert_equal(-1, @store.index_last_selected, 'プリセット未選択状態になる')

        delete_result = @store.delete('Config 1')
        assert_equal(-1, delete_result, '項目が見つからない')
        assert_equal(1, @store.length, '個数が変わらない')

        delete_result = @store.delete('デフォルト')
        assert_equal(-1, delete_result, '最後の1個は消すことができない')
        assert_equal(1, @store.length, '個数が変わらない')
      end

      test 'registered preset_delete handlers should be called after deleting preset' do
        @store.push(@config1)
        @store.push(@config2)

        preset_index = nil
        preset_name = nil

        @store.add_preset_delete_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        @store.delete('Config 1')

        assert_equal(1, preset_index)
        assert_equal('Config 1', preset_name)
      end

      test 'registered preset_delete handlers should not be called after trying to delete non-existing preset' do
        @store.push(@config1)
        @store.push(@config2)

        preset_index = nil
        preset_name = nil

        @store.add_preset_delete_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        @store.delete('Config 2')

        assert_nil(preset_index)
        assert_nil(preset_name)
      end

      test 'empty?' do
        assert_true(@store.empty?, '最初は true')

        @store.push(@config1)
        assert_false(@store.empty?, '設定追加後は false')
      end

      test 'have_multiple_presets?' do
        assert_false(@store.have_multiple_presets?, '0個では false')

        @store.push(@config1)
        assert_false(@store.have_multiple_presets?, '1個では false')

        @store.push(@config2)
        assert_true(@store.have_multiple_presets?, '2個では true')
      end

      test 'index_last_selected=' do
        assert(@store.empty?)

        @store.index_last_selected = -1
        assert_equal(-1, @store.index_last_selected)

        assert_raise(RangeError) do
          @store.index_last_selected = 0
        end

        @store.push(@config1)
        @store.push(@config2)
        assert_equal(2, @store.length)

        @store.index_last_selected = 1
        assert_equal(1, @store.index_last_selected)

        @store.index_last_selected = 0
        assert_equal(0, @store.index_last_selected)

        @store.index_last_selected = -1
        assert_equal(-1, @store.index_last_selected)

        assert_raise(RangeError) do
          @store.index_last_selected = -2
        end

        assert_raise(RangeError) do
          @store.index_last_selected = 2
        end
      end

      test 'include?' do
        @store.push(@config1)
        @store.push(@config2)

        assert(@store.include?('デフォルト'))
        assert(@store.include?('Config 1'))
        refute(@store.include?('Config 2'))
      end

      test 'fetch_by_index' do
        @store.push(@config1)
        @store.push(@config2)

        c2 = @store.fetch_by_index(1)
        assert_equal('Config 1', c2.name)

        c1 = @store.fetch_by_index(0)
        assert_equal('デフォルト', c1.name)

        assert_raise(IndexError) do
          @store.fetch_by_index(2)
        end
      end

      test 'fetch_by_name' do
        @store.push(@config1)
        @store.push(@config2)

        c2 = @store.fetch_by_name('Config 1')
        assert_equal('irc.example.net', c2.hostname)

        c1 = @store.fetch_by_name('デフォルト')
        assert_equal('irc.trpg.net', c1.hostname)

        assert_raise(IndexError) do
          @store.fetch_by_index(2)
        end
      end

      test 'from_hash' do
        hash = YAML.load_file(@yaml_path)
        @store.from_hash(hash)

        assert_equal(['デフォルト', 'Config 1'], @store.map(&:name))
        assert_equal(1, @store.index_last_selected)
      end

      test 'to_h' do
        @store.push(@config1)
        @store.push(@config2)

        hash2 = @store.to_h
        preset_names = hash2[:presets].map { |h| h[:name] }
        assert_equal(['デフォルト', 'Config 1'], preset_names)
        assert_equal(1, hash2[:index_last_selected])
      end

      test 'load_yaml_file' do
        @store.load_yaml_file(@yaml_path)

        assert_equal(['デフォルト', 'Config 1'], @store.map(&:name))
        assert_equal(1, @store.index_last_selected)
      end

      test 'write_yaml_file' do
        @store.load_yaml_file(@yaml_path)
        @store.write_yaml_file(YAML_PATH_TO_WRITE)
        @store.load_yaml_file(YAML_PATH_TO_WRITE)

        assert_equal(['デフォルト', 'Config 1'], @store.map(&:name))
        assert_equal(1, @store.index_last_selected)
      end

      test '.default' do
        store = PresetStore.default
        assert_equal(['デフォルト'], store.map(&:name))
        assert_equal(0, store.index_last_selected)
      end

      test 'save new preset' do
        @store.push(@config1)
        result = @store.push(@config2)

        assert_equal(:appended, result)
        assert_equal('Config 1', @store.fetch_by_index(1).name)
        assert_equal(2, @store.length)
        assert_equal('irc.example.net', @store.fetch_by_name('Config 1').hostname)
        assert_equal(1, @store.index_last_selected)
        assert_equal(:update, @store.preset_save_action)
        assert_equal(true, @store.can_delete_preset?)
      end

      test 'save existing preset' do
        @store.push(@config1)
        @store.push(@config2)

        config1_modified = @config1.dup
        config1_modified.hostname = 'irc2.example.net'

        result = @store.push(config1_modified)

        assert_equal(:updated, result)
        assert_equal('デフォルト', @store.fetch_by_index(0).name)
        assert_equal(2, @store.length)
        assert_equal('irc2.example.net', @store.fetch_by_name('デフォルト').hostname)
        assert_equal(0, @store.index_last_selected)
        assert_equal(:update, @store.preset_save_action)
        assert_equal(true, @store.can_delete_preset?)
      end

      test 'registered preset_append handlers should be called after saving new preset' do
        @store.push(@config1)

        preset_index = nil
        preset_name = nil

        @store.add_preset_append_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        @store.push(@config2)

        assert_equal(1, preset_index)
        assert_equal('Config 1', preset_name)
      end

      test 'registered preset_update handlers should be called after saving existing preset' do
        @store.push(@config1)
        @store.push(@config2)

        preset_index = nil
        preset_name = nil

        @store.add_preset_update_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        config1_modified = @config1.dup
        config1_modified.hostname = 'irc2.example.net'

        result = @store.push(config1_modified)

        assert_equal(0, preset_index)
        assert_equal('デフォルト', preset_name)
      end

      test 'load_by_index should set index_last_selected as specified' do
        @store.push(@config1)
        @store.push(@config2)

        result = @store.load_by_index(0)

        assert_equal(0, @store.index_last_selected)
        assert_same(@store, result)
      end

      test 'load_by_index should set temporary_preset_name to the name of the specified preset' do
        @store.push(@config1)
        @store.push(@config2)

        result = @store.load_by_index(0)

        assert_equal('デフォルト', @store.temporary_preset_name)
        assert_same(@store, result)
      end

      test 'load_by_index should call registered preset_load handlers' do
        @store.push(@config1)
        @store.push(@config2)

        preset_index = nil
        preset_name = nil

        @store.add_preset_load_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        @store.load_by_index(0)

        assert_equal(0, preset_index)
        assert_equal('デフォルト', preset_name)
      end

      test 'load_by_index(-1) should do nothing' do
        @store.push(@config1)
        @store.push(@config2)

        preset_index = nil
        preset_name = nil

        @store.add_preset_load_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        @store.load_by_index(-1)

        assert_equal(1, @store.index_last_selected)
        assert_nil(preset_index)
        assert_nil(preset_name)
      end

      test 'load_by_name should set index_last_selected to the index of the specified preset' do
        @store.push(@config1)
        @store.push(@config2)

        result = @store.load_by_name('デフォルト')

        assert_equal(0, @store.index_last_selected)
        assert_same(@store, result)
      end

      test 'load_by_name should set temporary_preset_name to the name of the specified preset' do
        @store.push(@config1)
        @store.push(@config2)

        result = @store.load_by_name('デフォルト')

        assert_equal('デフォルト', @store.temporary_preset_name)
        assert_same(@store, result)
      end

      test 'load_by_name should call registered preset_load handlers' do
        @store.push(@config1)
        @store.push(@config2)

        preset_index = nil
        preset_name = nil

        @store.add_preset_load_handlers(
          ->(_config, index) { preset_index = index },
          ->(config, _index) { preset_name = config.name }
        )

        @store.load_by_name('デフォルト')

        assert_equal(0, preset_index)
        assert_equal('デフォルト', preset_name)
      end

      data('空文字列', ['', :none])
      data('空白のみ', [' 　', :none])
      data('既存1', ['デフォルト', :update])
      data('既存2', ['Config 1', :update])
      data('新規', ['Config 2', :append])
      test 'temporary_preset_name and preset_save_action' do |data|
        temporary_preset_name, expected_action = data

        @store.push(@config1)
        @store.push(@config2)

        @store.temporary_preset_name = temporary_preset_name

        assert_equal(expected_action, @store.preset_save_action)
      end

      data('空文字列', '')
      data('空白のみ', ' 　')
      data('既存1', 'デフォルト')
      data('新規', 'Config 2')
      test 'temporary_preset_name and can_delete_preset? (single preset)' do |data|
        temporary_preset_name = data

        @store.push(@config1)

        @store.temporary_preset_name = temporary_preset_name

        assert_equal(false, @store.can_delete_preset?)
      end

      data('空文字列', ['', false])
      data('空白のみ', [' 　', false])
      data('既存1', ['デフォルト', true])
      data('既存2', ['Config 1', true])
      data('新規', ['Config 2', false])
      test 'temporary_preset_name and can_delete_preset? (multiple presets)' do |data|
        temporary_preset_name, expected = data

        @store.push(@config1)
        @store.push(@config2)

        @store.temporary_preset_name = temporary_preset_name

        assert_equal(expected, @store.can_delete_preset?)
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

        @store.add_preset_save_action_updated_handlers(
          ->action { preset_save_button_sensitive = action != :none },
          lambda do |action|
            preset_save_button_label = action == :update ? 'Update' : 'Save'
          end
        )

        @store.temporary_preset_name = temporary_preset_name

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

        @store.add_preset_deletability_updated_handlers(
          ->can_delete_preset { preset_delete_button_sensitive = can_delete_preset }
        )

        @store.temporary_preset_name = temporary_preset_name

        assert_equal(expected_sensitive, preset_delete_button_sensitive)
      end
    end
  end
end
