# frozen_string_literal: true

require 'bcdiceCore'
require 'diceBot/DiceBotLoader'

require 'bcdice_irc_pb'
require 'bcdice_irc_services_pb'

require_relative '../version'
require_relative '../dice_bot_wrapper'

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

        dice_bots = [DiceBot.new] + DiceBotLoader.collectDiceBots
        # ダイスボットラッパの配列
        @dice_bot_wrappers = dice_bots.map { |b| DiceBotWrapper.wrap(b) }
      end

      # Version はBCDice IRCおよび関連プログラムのバージョン情報を返す
      def version(_request, _call)
        Proto::VersionResponse.new(
          bcdice: BCDice::VERSION,
          bcdice_irc: BCDiceIRC::VERSION
        )
      end

      # GetDiceBotList は、ダイスボットの一覧を返す
      def get_dice_bot_list(_request, _call)
        proto_dice_bots = @dice_bot_wrappers.map { |b|
          Proto::DiceBot.new(
            id: b.id,
            name: b.name,
            help_message: b.help_message
          )
        }

        Proto::GetDiceBotListResponse.new(dice_bots: proto_dice_bots)
      end

      # Stop はサービスを停止する
      def stop(_request, _call)
        @server.stop
        Proto::StopResponse.new
      end
    end
  end
end
