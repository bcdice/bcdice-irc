# frozen_string_literal: true

require 'gtk3'

require 'bcdiceCore'
require 'diceBot/DiceBot'
require 'diceBot/DiceBotLoader'

require 'bcdice-irc/version'

module BCDiceIRC
  module GUI
    class Application
      def initialize
        @builder = Gtk::Builder.new
        @bot_class = nil
      end

      def run!
        load_glade_file
        setup_components
        @main_window.show_all
        Gtk.main
      end

      def bot_class=(value)
        @bot_class = value

        @help_text_view.buffer.text = @bot_class::HELP_MESSAGE
      end

      private

      def load_glade_file
        glade_file = File.expand_path('bcdice-irc.glade', __dir__)
        @builder.add_from_file(glade_file)
        @builder.connect_signals { |handler| method(handler) }
      end

      def setup_components
        setup_main_window
        setup_version_labels
        setup_game_system_combo_box
      end

      def setup_main_window
        @main_window = @builder.get_object('main_window')

        @game_system_combo_box = @builder.get_object('game_system_combo_box')
        @help_text_view = @builder.get_object('help_text_view')

        @bcdice_irc_version_label = @builder.get_object('bcdice_irc_version_label')
        @bcdice_version_label = @builder.get_object('bcdice_version_label')
      end

      def setup_version_labels
        @bcdice_irc_version_label.text =
          @bcdice_irc_version_label.text % BCDiceIRC::VERSION
        @bcdice_version_label.text =
          @bcdice_version_label.text % BCDice::VERSION
      end

      def setup_game_system_combo_box
        game_system_list_store = Gtk::ListStore.new(Class, String)
        bot_classes = [DiceBot] + DiceBotLoader.collectDiceBots.map(&:class)
        bot_classes.each do |bot_class|
          row = game_system_list_store.append
          row[0] = bot_class
          row[1] = bot_class::NAME
        end

        @game_system_combo_box.model = game_system_list_store

        @game_system_cell_render = Gtk::CellRendererText.new
        @game_system_combo_box.pack_start(@game_system_cell_render, true)
        @game_system_combo_box.add_attribute(@game_system_cell_render, 'text', 1)
        @game_system_combo_box.active = 0
      end

      def main_window_on_destroy
        Gtk.main_quit
      end

      def game_system_combo_box_on_changed
        self.bot_class = @game_system_combo_box.active_iter[0]
      end
    end
  end
end
