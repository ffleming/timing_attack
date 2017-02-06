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
      @basic_auth_username = params_from(
        options.fetch(:basic_auth_username, "")
      )
      @basic_auth_password = params_from(
        options.fetch(:basic_auth_password, "")
      )
    end

    def generate_hydra_request!
      req = Typhoeus::Request.new(url, **typhoeus_opts)
      @hydra_requests.push req
      req
    end

    def typhoeus_opts
      {
        method: options.fetch(:method),
        followlocation: true,
      }.tap do |h|
        h[:params] = params unless params.empty?
        h[:body] = body unless body.empty?
        h[:userpwd] = typhoeus_basic_auth unless typhoeus_basic_auth.empty?
      end
    end

    def typhoeus_basic_auth
      return "" if basic_auth_username.empty? && basic_auth_password.empty?
      "#{basic_auth_username}:#{basic_auth_password}"
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
    attr_reader :basic_auth_username, :basic_auth_password
  end
end
