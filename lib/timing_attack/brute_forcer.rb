module TimingAttack
  class BruteForcer
    def initialize(options: {})
      @options = DEFAULT_OPTIONS.merge(options)
      raise ArgumentError.new("Must provide :url key") if url.nil?
      @concurrency = options.fetch(:concurrency, 3)
      @iterations = options.fetch(:iterations, 20)
    end

    def run!
      puts "Target: #{url}" if verbose?
      attack!
    end

    private
    attr_reader :attacks, :options

    %i(iterations url verbose width method mean percentile threshold concurrency).each do |sym|
      define_method(sym) { options.fetch sym }
    end
    alias_method :verbose?, :verbose

    BYTES = (' '..'z').to_a
    def attack!
      known = ""
      while(true)
        attacks = BYTES.map do |byte|
          TimingAttack::TestCase.new(input: "#{known}#{byte}",
                                      options: {
                                                 url: url,
                                                 method: :get,
                                               })
        end
        hydra = Typhoeus::Hydra.new(max_concurrency: concurrency)
        iterations.times do
          attacks.each do |attack|
            req = attack.generate_hydra_request!
            req.on_complete do |response|
              puts "\e[H\e[2J"
              puts "#{spinner} '#{known}'"
            end
            hydra.queue req
          end
        end
        hydra.run
        attacks.each(&:process!)
        grouper = Grouper.new(attacks: attacks, group_by: { percentile: 3 })
        results = grouper.long_tests.map(&:input)
        if grouper.long_tests.count > 1
          raise StandardError.new("Got too many possibilities: #{results.join(', ')}")
        end
        known = results.first
      end
    end

    SPINNER = %w(| / - \\)
    def spinner
      @spinner_i ||= 0
      @spinner_i += 1
      SPINNER[@spinner_i % SPINNER.length]
    end

    def attack_byte!
      hydra = Typhoeus::Hydra.new(max_concurrency: concurrency)
      iterations.times do
        attacks.each do |attack|
          req = attack.generate_hydra_request!
          req.on_complete do |response|
            attack_bar.increment
          end
          hydra.queue req
        end
      end
      hydra.run
      attacks.each(&:process!)
    end
  end

  DEFAULT_OPTIONS = {
    verbose: false,
    method: :get,
    iterations: 50,
    mean: false,
    percentile: 3,
    concurrency: 15,
  }.freeze
end
