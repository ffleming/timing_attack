module TimingAttack
  class Enumerator
    include TimingAttack::Attacker

    def initialize(inputs: [], options: {})
      @inputs = inputs
      raise ArgumentError.new("Need at least 2 inputs") if inputs.count < 2
      super(options: options)
      @attacks = inputs.map { |input| TestCase.new(input: input, options: @options) }
    end

    def run!
     super
     puts report
    end

    private

    attr_reader :grouper, :inputs

    def report
      ret = ''
      hsh = grouper.serialize
      if hsh[:spike_delta] < threshold
        ret << "\n* Spike delta of #{sprintf('%.4f', hsh[:spike_delta])} is less than #{sprintf('%.4f', threshold)} * \n\n"
      end
      [:short, :long].each do |sym|
        ret << "#{sym.to_s.capitalize} tests:\n"
        hsh.fetch(sym).each do |input, time|
          ret << "  #{input.ljust(width)}"
          ret << sprintf('%.4f', time) << "\n"
        end
      end
      ret
    end

    def attack!
      hydra = Typhoeus::Hydra.new(max_concurrency: concurrency)
      iterations.times do
        attacks.each do |attack|
          req = attack.generate_hydra_request!
          req.on_complete do |response|
            output.increment
          end
          hydra.queue req
        end
      end
      hydra.run
      attacks.each(&:process!)
    end

    def grouper
      return @grouper unless @grouper.nil?
      group_by = if options.fetch(:mean, false)
                    :mean
                  else
                    { percentile: options.fetch(:percentile) }
                  end
      @grouper = Grouper.new(attacks: attacks, group_by: group_by)
    end

    def output
      return null_bar unless verbose?
      @output ||= ProgressBar.create(title: "  Attacking".ljust(15),
                                         total: iterations * attacks.length,
                                         format: bar_format
                                        )
    end

    def bar_format
      @bar_format ||= "%t (%E) |%B|"
    end

    def null_bar
      @null_bar_klass ||= Struct.new('NullProgressBar', :increment)
      @null_bar ||= @null_bar_klass.new
    end

    def default_options
      super.merge(
        width: inputs.dup.map(&:length).push(30).sort.last,
      ).freeze
    end
  end
end
