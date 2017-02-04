require 'uri'
module TimingAttack
  module TestCases
    class Base
      attr_reader :input
      def initialize(input: , options: {})
        @input = input
        @options = options
        @times = []
        @percentiles = []
        @hydra_requests = []
        # @params = params_from(options.fetch(:params))
        @url = URI.escape options.fetch(:url).gsub(INPUT_FLAG, input)
      end

      def generate_hydra_request!
        req = Typhoeus::Request.new(
          @url,
          method: options.fetch(:method),
          # params: params,
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

      INPUT_FLAG = "INPUT"
      def params_from(obj)
        case obj
        when String
          obj.gsub(INPUT_FLAG, input)
        when Array
          obj.map { |el| params_from(el) }
        when Hash
          Hash[obj.map {|k,v| [params_from(k), params_from(v)]}]
        when Symbol
          params_from(obj.to_s).to_sym
        else
          obj
        end
      end

      attr_reader :times, :options, :percentiles#, :params
    end
  end
end
