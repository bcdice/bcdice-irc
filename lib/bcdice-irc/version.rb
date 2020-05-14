# frozen_string_literal: true

require 'open3'

module BCDiceIRC
  # バージョン番号
  VERSION = '1.0.0-alpha.1'

  # コミットID
  COMMIT_ID = Dir.chdir(__dir__) do
    begin
      Dir.chdir(__dir__) do
        Open3.popen3('git log -1 --format=%h') do |_, stdout, _, _|
          stdout.gets&.strip
        end
      end
    rescue
      nil
    end
  end
end
