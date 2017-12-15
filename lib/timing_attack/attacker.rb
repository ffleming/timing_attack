module TimingAttack
  module Attacker
    def initialize(options: {}, inputs: [])
      @options = default_options.merge(options)
      raise ArgumentError.new("Must provide url") if url.nil?
      unless specified_input_option?
        msg = "'#{INPUT_FLAG}' not found in url, parameters, body, headers, or HTTP authentication options"
        raise ArgumentError.new(msg)
      end
      raise ArgumentError.new("Iterations can't be < 3") if iterations < 3
    end

    def run!
      if verbose?
        puts "Target: #{url}"
        puts "Method: #{method.to_s.upcase}"
        puts "Parameters: #{params.inspect}" unless params.empty?
        puts "Headers: #{headers.inspect}" unless headers.empty?
        puts "Body: #{body.inspect}" unless body.empty?
      end
      attack!
    end

    private
    attr_reader :attacks, :options

    %i(iterations url verbose width method mean percentile threshold concurrency params body headers).each do |sym|
      define_method(sym) { options.fetch sym }
    end
    alias_method :verbose?, :verbose

    def default_options
      {
        verbose: true,
        method: :get,
        iterations: 50,
        mean: false,
        threshold: 0.025,
        percentile: 3,
        concurrency: 15,
        params: {},
        body: {},
        headers: {},
        basic_auth_username: "",
        basic_auth_password: ""
      }.freeze
    end

    def option_contains_input?(obj)
      case obj
      when String
        obj.include?(INPUT_FLAG)
      when Symbol
        option_contains_input?(obj.to_s)
      when Array
        obj.any? {|el| option_contains_input?(el) }
      when Hash
        option_contains_input?(obj.keys) || option_contains_input?(obj.values)
      end
    end

    def input_options
      @input_options ||= %i(basic_auth_password basic_auth_username body params url headers)
    end

    def specified_input_option?
      input_options.any? { |opt| option_contains_input?(options[opt]) }
    end
  end
end
