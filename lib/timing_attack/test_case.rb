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
      @url = URI.escape(
        options.fetch(:url).
        gsub(INPUT_FLAG, input)
      )
      @params = params_from(options.fetch :params, {})
      @body = params_from(options.fetch :body, {})
    end

    def generate_hydra_request!
      req = Typhoeus::Request.new(
        url,
        method: options.fetch(:method),
        followlocation: true,
        params: params,
        body: body
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

    def params_from(obj)
      case obj
      when String
        obj.gsub(INPUT_FLAG, input)
      when Symbol
        params_from(obj.to_s).to_sym
      when Hash
        Hash[obj.map {|k, v| [params_from(k), params_from(v)]}]
      when Array
        obj.map {|el| params_from(el) }
      else
        obj
      end
    end

    attr_reader :times, :options, :percentiles, :url, :params, :body
  end
end
