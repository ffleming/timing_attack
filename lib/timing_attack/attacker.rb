module TimingAttack
  module Attacker
    def initialize(options: {})
      @options = DEFAULT_OPTIONS.merge(options)
      raise ArgumentError.new("Must provide :url key") if url.nil?
      @concurrency = options.fetch(:concurrency, 3)
      @iterations = options.fetch(:iterations, 20)
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
  end
end
