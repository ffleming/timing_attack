module TimingAttack
  class TestCase
    attr_reader :input
    def initialize(input: , options: {})
      @input = input
      @options = options
      @times = []
      @percentiles = []
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

    def mean
      times.reduce(:+) / times.size.to_f
    end

    def percentile(n)
      raise ArgumentError.new("Can't have a percentile > 100") if n > 100
      if percentiles[n].nil?
        position = ((times.length - 1) * (n/100.0)).to_i
        percentiles[n] = times.sort[position]
      else
        percentiles[n]
      end
    end

    private

    attr_reader :times, :options, :percentiles
  end
end
