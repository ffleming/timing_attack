module TimingAttack
  class Grouper
    attr_reader :short_tests, :long_tests
    def initialize(attacks: , group_by: {})
      @attacks = attacks
      setup_grouping_opts!(group_by)
      @short_tests = []
      @long_tests = []
      group_attacks
      serialize
      freeze
    end

    def serialize
      @serialize ||= {}.tap do |h|
        h[:attack_method] = test_method
        h[:attack_args]   = test_args
        h[:short]         = serialize_tests(short_tests)
        h[:long]          = serialize_tests(long_tests)
        h[:spike_delta]   = spike_delta
      end
    end

    private

    ALLOWED_TEST_SYMBOLS = %i(mean median percentile).freeze

    attr_reader :test_method, :test_args, :attacks, :test_hash, :spike_delta

    def setup_grouping_opts!(group_by)
      case group_by
      when Symbol
        setup_symbol_opts!(group_by)
      when Hash
        setup_hash_opts!(group_by)
      else
        raise ArgumentError.new("Don't know what to do with #{group_by.class} #{group_by}")
      end
    end

    def setup_symbol_opts!(symbol)
      case symbol
      when :mean
        @test_method = :mean
        @test_args = []
      when :median
        @test_method = :percentile
        @test_args = [50]
      when :percentile
        @test_method = :percentile
        @test_args = [10]
      else
        raise ArgumentError.new("Allowed symbols are #{ALLOWED_TEST_SYMBOLS.join(', ')}")
      end
    end

    def setup_hash_opts!(hash)
      raise ArgumentError.new("Must provide configuration to Grouper") if hash.empty?
      key, value = hash.first
      unless ALLOWED_TEST_SYMBOLS.include? key
        raise ArgumentError.new("Allowed keys are #{ALLOWED_TEST_SYMBOLS.join(', ')}")
      end
      @test_method = key
      @test_args = value.is_a?(Array) ? value : [value]
    end

    def value_from_test(test)
      test.public_send(test_method, *test_args)
    end

    def serialize_tests(test_arr)
      test_arr.each_with_object({}) do |test, ret|
        ret[test.input] = value_from_test(test)
      end
    end

    def group_attacks
      spike = decorated_attacks.max { |a,b| a[:delta] <=> b[:delta] }
      index = decorated_attacks.index(spike)
      stripped = decorated_attacks.map {|a| a[:attack] }
      @short_tests = stripped[0..(index-1)]
      @long_tests = stripped[index..-1]
      @spike_delta = spike[:delta]
    end

    def decorated_attacks
      return @decorated_attacks unless @decorated_attacks.nil?
      sorted = attacks.sort { |a,b| value_from_test(a) <=> value_from_test(b) }
      @decorated_attacks = sorted.each_with_object([]).with_index do |(attack, memo), index|
        delta = if index == 0
                  0.0
                else
                  value_from_test(attack) - value_from_test(sorted[index-1])
                end
        memo << { attack: attack, delta: delta }
      end
    end
  end
end
