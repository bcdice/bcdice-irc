# frozen_string_literal: true

module BCDiceIRC
  module GUI
    # 直前の値との比較結果をもとに変更を通知する処理のクラス
    class SimpleObservable
      attr_reader :value

      # 初期化する
      # @param [Object] initial_value 初期値
      def initialize(initial_value: nil)
        @value = initial_value
        @update_procs = []
      end

      # オブザーバ（値が変更されたときに実行する手続き）を追加する
      # @param [Proc] update_proc 値が変更されたときに実行する更新手続き
      # @return [self]
      def add_observer(update_proc)
        @update_procs.push(update_proc)
        self
      end

      # 複数のオブザーバを追加する
      # @param [Proc] update_procs 値が変更されたときに実行する更新手続き
      # @return [self]
      def add_observers(*update_procs)
        update_procs.each do |update_proc|
          add_observer(update_proc)
        end

        self
      end

      # 変更を通知する
      # @return [self]
      def notify_observers
        @update_procs.each do |update|
          update[@value]
        end

        self
      end

      # 値を設定し、変更をオブザーバに通知する
      # @param [Object] value 設定する値
      def value=(value)
        @value = value
        notify_observers
      end
    end
  end
end
