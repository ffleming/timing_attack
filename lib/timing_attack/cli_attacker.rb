module TimingAttack
  class CliAttacker
    def initialize(inputs: [], options: {})
      @options = DEFAULT_OPTIONS.merge(options)
      raise ArgumentError.new("url is a required argument") unless options.has_key? :url
      raise ArgumentError.new("Need at least 2 inputs") if inputs.count < 2
      raise ArgumentError.new("Iterations can't be < 3") if iterations < 3
      unless @options.has_key? :width
        @options[:width] = inputs.dup.map(&:length).push(30).sort.last
      end
      @attacks = inputs.map { |input| TestCase.new(input: input, options: @options) }
    end

    def run!
      puts "Target: #{url}" if verbose?
      warmup!
      attack!
      puts report
    end

    private

    attr_reader :attacks, :options, :grouper

    def report
      ret = ''
      hsh = grouper.serialize
      [:short, :long].each do |sym|
        ret << "#{sym.to_s.capitalize} tests:\n"
        hsh.fetch(sym).each do |input, time|
          ret << "  #{input.ljust(width)}"
          ret << sprintf('%.4f', time) << "\n"
        end
      end
      ret
    end

    def warmup!
      2.times do
        warmup = TestCase.new(input: attacks.sample.input, options: options)
        warmup.test!
      end
    end

    def attack!
      iterations.times do
        attacks.each do |attack|
          attack.test!
          attack_bar.increment
        end
      end
    end

    def grouper
      return @grouper unless @grouper.nil?
      group_by = if options.fetch(:mean, false)
                    :mean
                  else
                    { percentile: options.fetch(:percentile) }
                  end
      @grouper = Grouper.new(attacks: attacks, group_by: group_by, threshold: threshold)
    end

    def attack_bar
      return null_bar unless verbose?
      @attack_bar ||= ProgressBar.create(title: "  Attacking".ljust(15),
                                         total: iterations * attacks.length,
                                         format: bar_format
                                        )
    end

    def benchmark_bar
      return null_bar unless verbose?
      @benchmark_bar ||= ProgressBar.create(title: "  Benchmarking".ljust(15),
                                            total: iterations * 2,
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

    %i(iterations url verbose width method mean percentile threshold).each do |sym|
      define_method(sym) { options.fetch sym }
    end
    alias_method :verbose?, :verbose

    DEFAULT_OPTIONS = {
      verbose: false,
      method: :get,
      iterations: 5,
      mean: false,
      threshold: 0.05,
      percentile: 10
    }.freeze
  end
end
