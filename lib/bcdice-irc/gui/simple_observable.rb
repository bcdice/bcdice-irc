# frozen_string_literal: true

module BCDiceIRC
  module GUI
    # 直前の値との比較結果をもとに変更を通知する処理のクラス
    class SimpleObservable
      attr_reader :value

      # @param [Object] last_value 直前の値
      # @param [Boolean] compare 直前の値と比較するか
      def initialize(initial_value: nil, compare: false)
        @value = initial_value
        @compare = compare
        @update_procs = []
      end

      # オブザーバ（値が変更されたときに実行する手続き）を追加する
      # @param [Proc] update_proc 値が変更されたときに実行する更新手続き
      # @return [self]
      def add_observer(update_proc)
        @update_procs << update_proc
        self
      end

      # 値を設定し、変化していたらオブザーバに通知する
      # @param [Object] new_value 設定する値
      # @return [Boolean] 値が変化したか
      def value=(new_value)
        # 値が変更されていなかったら何もしない
        return false if @compare && new_value == @value

        # 値が変更されていたら、変更後の値を記録し、変更を通知する
        @value = new_value
        @update_procs.each do |update|
          update[new_value]
        end

        true
      end
    end
  end
end
