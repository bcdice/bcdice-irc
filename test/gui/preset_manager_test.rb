# frozen_string_literal: true

require 'yaml'

require_relative '../test_helper'
require 'bcdice-irc/gui/preset_manager'

module BCDiceIRC
  module GUI
    class PresetManagerTest < Test::Unit::TestCase
      setup do
        @manager = PresetManager.new

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
        )

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
        )

        @yaml_path = File.expand_path('presets_test_data.yaml', __dir__)
      end

      test 'add and length/size/count' do
        @manager.add(@config1, @config2)

        assert_equal(2, @manager.length)
        assert_equal(2, @manager.size)
        assert_equal(2, @manager.count)
      end

      test 'empty?' do
        assert_true(@manager.empty?, '最初は true')

        @manager.add(@config1)
        assert_false(@manager.empty?, '設定追加後は false')
      end

      test 'index_last_selected=' do
        assert(@manager.empty?)

        @manager.index_last_selected = nil
        assert_nil(@manager.index_last_selected)

        assert_raise(TypeError) do
          @manager.index_last_selected = 0
        end

        @manager.add(@config1, @config2)
        assert_equal(2, @manager.length)

        @manager.index_last_selected = 1
        assert_equal(1, @manager.index_last_selected)

        @manager.index_last_selected = 0
        assert_equal(0, @manager.index_last_selected)

        assert_raise(RangeError) do
          @manager.index_last_selected = -1
        end

        assert_raise(RangeError) do
          @manager.index_last_selected = 2
        end
      end

      test 'include?' do
        @manager.add(@config1, @config2)

        assert(@manager.include?('デフォルト'))
        assert(@manager.include?('Config 1'))
        refute(@manager.include?('Config 2'))
      end

      test 'fetch_by_index' do
        @manager.add(@config1, @config2)

        c2 = @manager.fetch_by_index(1)
        assert_equal('Config 1', c2.name)

        c1 = @manager.fetch_by_index(0)
        assert_equal('デフォルト', c1.name)

        assert_raise(IndexError) do
          @manager.fetch_by_index(2)
        end
      end

      test 'fetch_by_name' do
        @manager.add(@config1, @config2)

        c2 = @manager.fetch_by_name('Config 1')
        assert_equal('irc.example.net', c2.hostname)

        c1 = @manager.fetch_by_name('デフォルト')
        assert_equal('irc.trpg.net', c1.hostname)

        assert_raise(IndexError) do
          @manager.fetch_by_index(2)
        end
      end

      test 'from_hash' do
        hash = YAML.load_file(@yaml_path)
        @manager.from_hash(hash)

        assert_equal(['デフォルト', 'Config 1'], @manager.map(&:name))
        assert_equal(1, @manager.index_last_selected)
      end

      test 'load_yaml_file' do
        @manager.load_yaml_file(@yaml_path)

        assert_equal(['デフォルト', 'Config 1'], @manager.map(&:name))
        assert_equal(1, @manager.index_last_selected)
      end

      test '.default' do
        manager = PresetManager.default
        assert_equal(['デフォルト'], manager.map(&:name))
        assert_equal(0, manager.index_last_selected)
      end
    end
  end
end
