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

require 'bcdice-irc'
require 'bcdice-irc/rpc/service'

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

opts.version = BCDiceIRC::VERSION
opts.release = BCDiceIRC::COMMIT_ID

opts.on('-b', '--bind', '<hostname>:<port>') do |value|
  host = value
end

opts.parse!

server = GRPC::RpcServer.new
server.add_http2_port(host, :this_port_is_insecure)
server.handle(BCDiceIRC::RPC::Service.new(server))

GRPC.logger.info("Running on #{host}")

# GRPCが文字列の破壊的変更を行っているため、変更可能な文字列を用意する
SIGNALS = %w(SIGINT SIGTERM).map(&:dup)
server.run_till_terminated_or_interrupted(SIGNALS, 60)
