# frozen_string_literal: true

require 'gtk3'

require 'bcdiceCore'
require 'diceBot/DiceBot'
require 'diceBot/DiceBotLoader'

require 'bcdice-irc/version'
require 'bcdice-irc/dice_bot_wrapper'
require 'bcdice-irc/irc_bot'
require 'bcdice-irc/irc_bot/config'

require_relative 'mediator'

module BCDiceIRC
  module GUI
    class Application
      def initialize(log_level = :info)
        @builder = Gtk::Builder.new
        @dice_bot_wrapper = nil

        @mutex = Mutex.new
        @state = :disconnected

        @mediator = Mediator.new(self, log_level)
      end

      def run!
        load_glade_file
        setup_components
        @main_window.show_all
        @mediator.start!
        Gtk.main
      end

      def dice_bot_wrapper=(value)
        @dice_bot_wrapper = value

        @help_text_view.buffer.text = @dice_bot_wrapper.help_message

        @status_bar.push(
          @status_bar_change_game_system,
          "ゲームシステムを「#{@dice_bot_wrapper.name}」に設定しました"
        )
      end

      def switch_to_connecting_state
        @mutex.synchronize do
          @connect_disconnect_button.label = 'gtk-connect'
          @connect_disconnect_button.sensitive = false

          @hostname_entry.sensitive = false
          @port_spin_button.sensitive = false
          @password_check_button.sensitive = false
          @password_entry.sensitive = false
          @nick_entry.sensitive = false
          @channel_entry.sensitive = false
          @game_system_combo_box.sensitive = false

          @status_bar.push(@status_bar_connection, '接続中...')

          @state = :connecting
        end
      end

      def switch_to_connected_state
        @mutex.synchronize do
          @hostname_entry.sensitive = false
          @port_spin_button.sensitive = false
          @password_check_button.sensitive = false
          @password_entry.sensitive = false
          @nick_entry.sensitive = false
          @channel_entry.sensitive = false
          @game_system_combo_box.sensitive = false

          @connect_disconnect_button.label = 'gtk-disconnect'
          @connect_disconnect_button.sensitive = true

          @state = :connected

          @status_bar.push(@status_bar_connection, "#{@irc_bot_config.hostname} に接続済み")
        end
      end

      def switch_to_disconnecting_state
        @mutex.synchronize do
          @connect_disconnect_button.label = 'gtk-disconnect'
          @connect_disconnect_button.sensitive = false

          @hostname_entry.sensitive = false
          @port_spin_button.sensitive = false
          @password_check_button.sensitive = false
          @password_entry.sensitive = false
          @nick_entry.sensitive = false
          @channel_entry.sensitive = false
          @game_system_combo_box.sensitive = false

          @state = :disconnecting

          @status_bar.push(@status_bar_connection, '接続を切断中...')
        end
      end

      def switch_to_disconnected_state(error = false)
        @mutex.synchronize do
          @hostname_entry.sensitive = true
          @port_spin_button.sensitive = true
          @password_check_button.sensitive = true
          @password_check_button.active = @password_check_button.active?
          @nick_entry.sensitive = true
          @channel_entry.sensitive = true
          @game_system_combo_box.sensitive = true

          @connect_disconnect_button.label = 'gtk-connect'
          @connect_disconnect_button.sensitive = true

          @state = :disconnected

          status_bar_message =
            if error
              "#{@irc_bot_config.hostname} に接続できませんでした"
            else
              "#{@irc_bot_config.hostname} から切断されました"
            end

          @status_bar.push(@status_bar_connection, status_bar_message)
        end
      end

      # @param [StandardError] e 発生した例外
      def show_connection_error_dialog(e)
        message_utf8 = e.message.encode('UTF-8', invalid: :replace, undef: :replace)
        dialog = Gtk::MessageDialog.new(
          parent: @main_window,
          flags: :destroy_with_parent,
          type: :error,
          buttons: :ok,
          message: "#{@irc_bot_config.hostname} に接続できませんでした:\n#{message_utf8}"
        )
        dialog.run
        dialog.destroy
      end

      # GUIスレッドのアイドル時間に、ブロックで与えられた処理を行う
      # @return [void]
      def in_idle_time
        GLib::Idle.add do
          yield
          false
        end
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
        setup_widgets_for_password
        setup_game_system_combo_box
      end

      def setup_main_window
        @main_window = @builder.get_object('main_window')

        @hostname_entry = @builder.get_object('hostname_entry')
        @port_spin_button = @builder.get_object('port_spin_button')
        @password_check_button = @builder.get_object('password_check_button')
        @password_entry = @builder.get_object('password_entry')
        @nick_entry = @builder.get_object('nick_entry')
        @channel_entry = @builder.get_object('channel_entry')
        @connect_disconnect_button = @builder.get_object('connect_disconnect_button')

        @game_system_combo_box = @builder.get_object('game_system_combo_box')
        @help_text_view = @builder.get_object('help_text_view')

        @bcdice_version_label = @builder.get_object('bcdice_version_label')

        @status_bar = @builder.get_object('status_bar')
        @status_bar_change_game_system = @status_bar.get_context_id('change game system')
        @status_bar_connection = @status_bar.get_context_id('connection')
      end

      def setup_version_labels
        @bcdice_version_label.text =
          @bcdice_version_label.text % [BCDiceIRC::VERSION, BCDice::VERSION]
      end

      def setup_widgets_for_password
        @password_check_button.active = false
      end

      def setup_game_system_combo_box
        game_system_list_store = Gtk::ListStore.new(Object, String)

        bots = [DiceBot.new] + DiceBotLoader.collectDiceBots
        bots.each do |bot|
          dice_bot_wrapper = DiceBotWrapper.wrap(bot)

          row = game_system_list_store.append
          row[0] = dice_bot_wrapper
          row[1] = dice_bot_wrapper.name
        end

        @game_system_combo_box.model = game_system_list_store

        @game_system_cell_render = Gtk::CellRendererText.new
        @game_system_combo_box.pack_start(@game_system_cell_render, true)
        @game_system_combo_box.add_attribute(@game_system_cell_render, 'text', 1)
        @game_system_combo_box.active = 0
      end

      def main_window_on_destroy
        @mediator.quit!
        Gtk.main_quit
      end

      def password_check_button_on_toggled
        @password_entry.sensitive = @password_check_button.active?
      end

      def game_system_combo_box_on_changed
        self.dice_bot_wrapper = @game_system_combo_box.active_iter[0]
      end

      def connect_disconnect_button_on_clicked
        case @state
        when :disconnected
          connect_button_on_clicked
        when :connected
          disconnect_button_on_clicked
        end
      end

      def connect_button_on_clicked
        switch_to_connecting_state

        @irc_bot_config = IRCBot::Config.new(
          hostname: @hostname_entry.text,
          port: @port_spin_button.value.to_i,
          password: @password_check_button.active? ? @password_entry.text : nil,
          nick: @nick_entry.text,
          channel: @channel_entry.text,
          quit_message: $quitMessage || 'さようなら'
        )

        @mediator.create_irc_bot(@irc_bot_config, @dice_bot_wrapper.id)
        @mediator.start_irc_bot!
      end

      def disconnect_button_on_clicked
        switch_to_disconnecting_state
        @mediator.quit_irc_bot!
      end
    end
  end
end
