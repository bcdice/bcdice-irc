# frozen_string_literal: true

bcdice_dir = File.expand_path(
  File.join('..', 'vendor', 'bcdice', 'src'),
  __dir__
)
lib_dir = File.expand_path(
  File.join('..', 'lib'),
  __dir__
)
dirs = [bcdice_dir, lib_dir]
dirs.each do |dir|
  $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir)
end

require 'test/unit'

require 'bcdice-irc'
