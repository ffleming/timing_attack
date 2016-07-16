module TimingAttack
  class TestCase
    attr_reader :input
    def initialize(input: , options: {})
      @input = input
      @options = options
      @times = []
    end

    def test!
      httparty_opts = {
        body: {
          login: input,
          password: "test" * 1000
        },
        timeout: 5
      }
      before = Time.now
      HTTParty.send(options.fetch(:method), options.fetch(:url), httparty_opts)
      diff = (Time.now - before)
      times.push(diff)
    end

    def to_s
      "#{input.ljust(options.fetch(:width))}~#{sprintf('%.4f', mean_time)}s"
    end

    def derive_group_from(a_test: , b_test: )
      unless a_test.is_a?(TestCase) && b_test.is_a?(TestCase)
        raise ArgumentError.new("a_test and b_test must be TestCases")
      end
      d_a = (mean_time - a_test.mean_time).abs
      d_b = (mean_time - b_test.mean_time).abs
      @group_a = (d_a < d_b)
    end

    def group_a
      raise ArgumentError.new("Have not yet determined group membership") if @group_a.nil?
      @group_a
    end
    alias_method :group_a?, :group_a

    def group_b
      !group_a
    end
    alias_method :group_b?, :group_b

    def mean_time
      times.reduce(:+) / times.size.to_f
    end

    private

    attr_reader :times, :options
  end
end
