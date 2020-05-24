# frozen_string_literal: true

require 'open3'

module BCDiceIRC
  # バージョン番号
  VERSION = '0.1.0'

  # コミットID
  COMMIT_ID = Dir.chdir(__dir__) do
    Dir.chdir(__dir__) do
      Open3.popen3('git log -1 --format=%h') do |_, stdout, _, _|
        stdout.gets&.strip
      end
    end
  rescue
    nil
  end
end
