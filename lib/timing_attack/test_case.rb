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

    def mean_time
      times.reduce(:+) / times.size.to_f
    end

    private

    attr_reader :times, :options
  end
end
