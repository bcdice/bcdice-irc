# frozen_string_literal: true

require 'forwardable'

module BCDiceIRC
  module GUI
    # オブザーバへの委譲を可能にするモジュール
    module ForwardableToObserver
      # オブザーバ用のアクセサを定義する
      # @param [String] var_name 変数名
      # @param [Boolean] private_reader 読み取り用メソッドを `private` にするか
      # @param [Boolean] private_writer 書き込み用メソッドを `private` にするか
      # @return [self]
      def def_accessor_for_observable(
        var_name,
        private_reader: false,
        private_writer: false
      )
        instance_var_name = "@#{var_name}"
        writer_name = "#{var_name}="

        def_delegator(instance_var_name, :value, var_name)
        def_delegator(instance_var_name, :value=, writer_name)

        private var_name if private_reader
        private writer_name if private_writer

        self
      end

      def self.extended(object)
        object.extend(Forwardable)
      end
    end
  end
end
