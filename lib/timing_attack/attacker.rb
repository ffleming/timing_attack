module TimingAttack
  module Attacker
    def initialize(options: {}, inputs: [])
      @options = default_options.merge(options)
      raise ArgumentError.new("Must provide :url key") if url.nil?
      raise ArgumentError.new("No fields specified for brute forcing") unless specified_input_field?
      raise ArgumentError.new("Iterations can't be < 3") if iterations < 3
    end

    def run!
      if verbose?
        puts "Target: #{url}"
        puts "Method: #{method.to_s.upcase}"
        puts "Parameters: #{params.inspect}" unless params.empty?
        puts "Body: #{body.inspect}" unless body.empty?
      end
      attack!
    end

    private
    attr_reader :attacks, :options

    %i(iterations url verbose width method mean percentile threshold concurrency params body).each do |sym|
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
      }.freeze
    end

    def field_contains_input?(obj)
      case obj
      when String
        obj.include?(INPUT_FLAG)
      when Symbol
        field_is_brute_forceable?(obj.to_s)
      when Array
        obj.any? {|el| field_is_brute_forceable?(el) }
      when Hash
        field_is_brute_forceable?(obj.keys) || field_is_brute_forceable?(obj.values)
      end
    end

    def specified_input_field?
      input_fields = [ options[:basic_auth_password], options[:basic_auth_username],
                      options[:body], options[:params], options[:url] ]
      input_fields.any? { |field| field_is_brute_forceable?(field) }
    end
  end
end
