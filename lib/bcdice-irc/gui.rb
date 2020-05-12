# frozen_string_literal: true

module BCDiceIRC
  # BCDice IRCのGUI関連の機能を格納するモジュール。
  module GUI; end
end

require_relative 'gui/mediator'
require_relative 'gui/state'
require_relative 'gui/preset_manager'
require_relative 'gui/combo_box_setup'
require_relative 'gui/application'