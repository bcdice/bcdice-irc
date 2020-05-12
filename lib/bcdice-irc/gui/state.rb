# frozen_string_literal: true

module BCDiceIRC
  module GUI
    # GUIの状態を格納するモジュール
    module State; end
  end
end

require_relative 'state/disconnected'
require_relative 'state/connecting'
require_relative 'state/connected'
require_relative 'state/disconnecting'
