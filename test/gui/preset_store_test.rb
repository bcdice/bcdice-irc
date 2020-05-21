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

        @yaml_path = File.expand_path('presets_test_data.yaml', __dir__)
      end

      teardown do
        FileUtils.rm_f(YAML_PATH_TO_WRITE)
      end

      test '#length, #size, #count' do
        @store.push(@config1)
        @store.push(@config2)

        assert_equal(2, @store.length)
        assert_equal(2, @store.size)
        assert_equal(2, @store.count)
      end

      test '#push should not change index_last_selected' do
        @store.push(@config1)
        @store.push(@config2)

        assert_equal(-1, @store.index_last_selected)
      end

      test '#delete' do
        @store.push(@config1)
        @store.push(@config2)
        @store.index_last_selected = 1

        result = @store.delete('Config 1')
        assert_true(result.deleted)
        assert_equal(1, result.index)
        assert_equal('Config 1', result.config.name)

        assert_equal(1, @store.length, '個数が1個減る')
        assert_equal(-1, @store.index_last_selected, 'プリセット未選択状態になる')

        result = @store.delete('Config 1')
        assert_false(result.deleted)
        assert_equal(-1, result.index)
        assert_equal(nil, result.config)

        assert_equal(1, @store.length, '個数が変わらない')

        result = @store.delete('デフォルト')
        assert_false(result.deleted)
        assert_equal(-1, result.index)
        assert_equal(nil, result.config)

        assert_equal(1, @store.length, '個数が変わらない')
      end

      test '#empty?' do
        assert_true(@store.empty?, '最初は true')

        @store.push(@config1)
        assert_false(@store.empty?, '設定追加後は false')
      end

      test '#multiple_presets?' do
        assert_false(@store.multiple_presets?, '0個では false')

        @store.push(@config1)
        assert_false(@store.multiple_presets?, '1個では false')

        @store.push(@config2)
        assert_true(@store.multiple_presets?, '2個では true')
      end

      data('-1', [-1, false])
      data( '0', [ 0, true])
      data('-2', [-2, true])
      test '#index_last_selected= if empty' do |data|
        value, error = data

        assert(@store.empty?)

        if error
          assert_raise(RangeError) do
            @store.index_last_selected = value
          end
        else
          @store.index_last_selected = value
          assert_equal(value, @store.index_last_selected)
        end
      end

      data( '1', [ 1, false])
      data( '0', [ 0, false])
      data('-1', [-1, false])
      data('-2', [-2, true])
      data( '2', [ 2, true])
      test '#index_last_selected= unless empty' do |data|
        value, error = data

        @store.push(@config1)
        @store.push(@config2)

        if error
          assert_raise(RangeError) do
            @store.index_last_selected = value
          end
        else
          @store.index_last_selected = value
          assert_equal(value, @store.index_last_selected)
        end
      end

      data('既存1', ['デフォルト', true])
      data('既存2', ['Config 1', true])
      data('非存在', ['Config 2', false])
      test '#include?' do |data|
        preset_name, expected = data

        @store.push(@config1)
        @store.push(@config2)

        assert_equal(expected, @store.include?(preset_name))
      end

      data('既存1', [0, 'デフォルト', false])
      data('既存2', [1, 'Config 1', false])
      data('非存在', [2, nil, true])
      test '#fetch_by_index' do |data|
        index, preset_name, error = data

        @store.push(@config1)
        @store.push(@config2)

        if error
          assert_raise(IndexError) do
            @store.fetch_by_index(index)
          end
        else
          config = @store.fetch_by_index(index)
          assert_equal(preset_name, config.name)
        end
      end

      data('既存1', ['デフォルト', 'irc.trpg.net', false])
      data('既存2', ['Config 1', 'irc.example.net', false])
      data('非存在', ['Config 2', nil, true])
      test 'fetch_by_name' do |data|
        preset_name, hostname, error = data

        @store.push(@config1)
        @store.push(@config2)

        if error
          assert_raise(KeyError) do
            @store.fetch_by_name(preset_name)
          end
        else
          config = @store.fetch_by_name(preset_name)
          assert_equal(hostname, config.hostname)
        end
      end

      test '#from_hash' do
        hash = YAML.load_file(@yaml_path)
        @store.from_hash(hash)

        assert_equal(['デフォルト', 'Config 1'], @store.map(&:name))
        assert_equal(1, @store.index_last_selected)
      end

      test '#to_h' do
        @store.push(@config1)
        @store.push(@config2)
        @store.index_last_selected = 1

        hash2 = @store.to_h
        preset_names = hash2[:presets].map { |h| h[:name] }
        assert_equal(['デフォルト', 'Config 1'], preset_names)
        assert_equal(1, hash2[:index_last_selected])
      end

      test '#load_default' do
        @store.load_default

        assert_equal(['デフォルト'], @store.map(&:name))
        assert_equal(0, @store.index_last_selected)
      end

      test '#load_yaml_file' do
        @store.load_yaml_file(@yaml_path)

        assert_equal(['デフォルト', 'Config 1'], @store.map(&:name))
        assert_equal(1, @store.index_last_selected)
      end

      test '#write_yaml_file' do
        @store.load_yaml_file(@yaml_path)
        @store.write_yaml_file(YAML_PATH_TO_WRITE)
        @store.load_yaml_file(YAML_PATH_TO_WRITE)

        assert_equal(['デフォルト', 'Config 1'], @store.map(&:name))
        assert_equal(1, @store.index_last_selected)
      end

      test 'save new preset' do
        @store.push(@config1)
        result = @store.push(@config2)

        assert_equal(:appended, result.action)
        assert_equal(1, result.index)
        assert_equal('Config 1', result.config.name)

        assert_equal('Config 1', @store.fetch_by_index(1).name)
        assert_equal(2, @store.length)
        assert_equal('irc.example.net', @store.fetch_by_name('Config 1').hostname)
        assert_equal(-1, @store.index_last_selected)
      end

      test 'save existing preset' do
        @store.push(@config1)
        @store.push(@config2)

        config1_modified = @config1.dup
        config1_modified.hostname = 'irc2.example.net'

        result = @store.push(config1_modified)

        assert_equal(:updated, result.action)
        assert_equal(0, result.index)
        assert_equal('デフォルト', result.config.name)

        assert_equal('デフォルト', @store.fetch_by_index(0).name)
        assert_equal(2, @store.length)
        assert_equal('irc2.example.net', @store.fetch_by_name('デフォルト').hostname)
        assert_equal(-1, @store.index_last_selected)
      end

      data('空文字列', ['', :none])
      data('空白のみ', [' 　', :none])
      data('既存1', ['デフォルト', :update])
      data('既存2', ['Config 1', :update])
      data('新規', ['Config 2', :append])
      test 'preset_save_action' do |data|
        preset_name, expected_action = data

        @store.push(@config1)
        @store.push(@config2)

        assert_equal(expected_action, @store.preset_save_action(preset_name))
      end

      data('空文字列', '')
      data('空白のみ', ' 　')
      data('既存1', 'デフォルト')
      data('新規', 'Config 2')
      test 'can_delete_preset? (single preset)' do |data|
        preset_name = data

        @store.push(@config1)

        assert_equal(false, @store.can_delete_preset?(preset_name))
      end

      data('空文字列', ['', false])
      data('空白のみ', [' 　', false])
      data('既存1', ['デフォルト', true])
      data('既存2', ['Config 1', true])
      data('新規', ['Config 2', false])
      test 'can_delete_preset? (multiple presets)' do |data|
        preset_name, expected = data

        @store.push(@config1)
        @store.push(@config2)

        assert_equal(expected, @store.can_delete_preset?(preset_name))
      end
    end
  end
end
