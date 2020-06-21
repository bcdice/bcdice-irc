# frozen_string_literal: true

require 'bcdiceCore'

require 'bcdice_irc_pb'
require 'bcdice_irc_services_pb'

require_relative '../version'

module BCDiceIRC
  module RPC
    Proto = ::BcdiceIrcProto

    # GUIアプリケーションとの通信サービス。
    class Service < Proto::BCDiceIRCService::Service
      # @param [GRPC::RpcServer] server GRPCサーバ
      def initialize(server)
        # GRPCサーバ
        # @type [GRPC::RpcServer]
        @server = server
      end

      # Version はBCDice IRCおよび関連プログラムのバージョン情報を返す
      def version(_request, _call)
        Proto::VersionResponse.new(
          bcdice: BCDice::VERSION,
          bcdice_irc: BCDiceIRC::VERSION
        )
      end

      # Stop はサービスを停止する
      def stop(_request, _call)
        @server.stop
        Proto::StopResponse.new
      end
    end
  end
end
