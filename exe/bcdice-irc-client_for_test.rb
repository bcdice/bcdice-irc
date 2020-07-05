#!/usr/bin/env ruby
# frozen_string_literal: true

bcdice_dir = File.expand_path(
  File.join('..', 'vendor', 'bcdice', 'src'),
  __dir__
)
proto_dir = File.expand_path(
  File.join('..', 'lib', 'bcdice_irc_proto'),
  __dir__
)
lib_dir = File.expand_path(
  File.join('..', 'lib'),
  __dir__
)
dirs = [bcdice_dir, proto_dir, lib_dir]
dirs.each do |dir|
  $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir)
end

require 'bundler/setup'

require 'logger'
require 'optparse'

require 'grpc'

require 'bcdice_irc_pb'
require 'bcdice_irc_services_pb'

require 'bcdice-irc'

# RubyLogger defines a logger for gRPC based on the standard ruby logger.
module RubyLogger
  def logger
    LOGGER
  end

  LOGGER = Logger.new($stdout)
end

# GRPC is the general RPC module
module GRPC
  # Inject the noop #logger if no module-level logger method has been injected.
  extend RubyLogger
end

host = 'localhost:50051'

opts = OptionParser.new

opts.banner = "Usage: #{opts.program_name} [options] command"
opts.version = BCDiceIRC::VERSION
opts.release = BCDiceIRC::COMMIT_ID

opts.on('-h', '--host', '<hostname>:<port>') do |value|
  host = value
end

opts.parse!

command = ARGV[0]
unless command
  $stderr.puts(opts.help)
  abort
end

Proto = BcdiceIrcProto
stub = Proto::BCDiceIRCService::Stub.new(
  host,
  :this_channel_is_insecure,
  timeout: 5
)

def on_version(stub)
  response = stub.version(Proto::VersionRequest.new)

  puts("BCDice: #{response.bcdice}")
  puts("BCDice IRC: #{response.bcdice_irc}")
end

def on_stop(stub)
  response = stub.stop(Proto::StopRequest.new)
  puts('OK')
end

def on_dicebots(stub)
  response = stub.get_dice_bot_list(Proto::GetDiceBotListRequest.new)

  game_system_name_id_list = response.dice_bots.map { |d|
    "#{d.name}（#{d.id}）"
  }

  puts(game_system_name_id_list)
end

case command
when 'version'
  on_version(stub)
when 'stop'
  on_stop(stub)
when 'dicebots'
  on_dicebots(stub)
else
  raise ArgumentError, "invalid command: #{command.inspect}"
end
