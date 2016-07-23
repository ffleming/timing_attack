module TimingAttack
  module Grouper
    class MeanGrouper
      attr_reader :group_a, :group_b
      def initialize(a_test: , b_test: , attacks: )
        unless a_test.is_a?(TestCase) && b_test.is_a?(TestCase)
          raise ArgumentError.new("a_test and b_test must be TestCases")
        end
        @group_a = []
        @group_b = []
        @a_test = a_test
        @b_test = b_test
        attacks.each {|attack| group_attack(attack) }
        freeze
      end

      private

      def group_attack(attack)
        d_a = (attack.mean_time - a_test.mean_time).abs
        d_b = (attack.mean_time - b_test.mean_time).abs
        if d_a < d_b
          group_a << attack
        else
          group_b << attack
        end
      end
    end
  end
end
