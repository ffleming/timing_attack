require 'uri'
module TimingAttack
  class TestCase
    INPUT_FLAG = "INPUT"

    attr_reader :input
    def initialize(input: , options: {})
      @input = input
      @options = options
      @times = []
      @percentiles = []
      @hydra_requests = []
      @url = URI.escape options.fetch(:url).gsub(INPUT_FLAG, input)
    end

    def generate_hydra_request!
      req = Typhoeus::Request.new(
        @url,
        method: options.fetch(:method),
        followlocation: true
      )
      @hydra_requests.push req
      req
    end

    def process!
      @hydra_requests.each do |request|
        response = request.response
        diff = response.time - response.namelookup_time
        @times.push(diff)
      end
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
