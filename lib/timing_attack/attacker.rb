module TimingAttack
  class Attacker
    def initialize(inputs: [], options: {})
      @options = DEFAULT_OPTIONS.merge(options)
      unless @options.has_key? :width
        @options[:width] = [a_name, b_name, *inputs].map(&:length).push(30).sort.last
      end
      %i(a_example b_example url).each do |arg|
        raise ArgumentError.new("#{arg} is a required argument") unless options.has_key? arg
      end
      @attacks = inputs.map { |input| TestCase.new(input: input, options: @options) }
    end

    def run!
      puts "Target: #{url}" if verbose?
      warmup!
      benchmark!
      attack!
      group!
    end

    def to_s
      ret = ""
      if verbose?
        ret << "Benchmark results\n"
        ret << "  #{a_name.ljust(width)}~#{sprintf('%.4f', a_benchmark.mean_time,)}s\n"
        ret << "  #{b_name.ljust(width)}~#{sprintf('%.4f', b_benchmark.mean_time)}s\n"
      end
      ret << attack_string
    end

    private

    attr_reader :attacks, :options, :grouper

    def warmup!
      @warmup_test ||= TestCase.new(input: a_example, options: options)
      2.times { @warmup_test.test! }
    end

    def benchmark!
      iterations.times do
        [a_benchmark, b_benchmark].each do |test_case|
          test_case.test!
          benchmark_bar.increment
        end
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

    def group!
      @grouper = grouper_klass.new(
        a_test: a_benchmark,
        b_test: b_benchmark,
        attacks: attacks
      )
    end

    def a_benchmark
      @a_benchmark ||= TestCase.new(input: a_example, options: options)
    end

    def b_benchmark
      @b_benchmark ||= TestCase.new(input: b_example, options: options)
    end

    def indent(str)
      "  #{str.ljust(width)}"
    end

    def a_attacks
      grouper.group_a
    end

    def b_attacks
      grouper.group_b
    end

    def attack_string
      ret = ""
      unless a_attacks.empty?
        ret << "#{a_name}:\n"
        ret << a_attacks.map {|a| indent(a.to_s)}.join("\n")
      end
      unless b_attacks.empty?
        ret << "\n#{b_name}:\n"
        ret << b_attacks.map {|a| indent(a.to_s)}.join("\n")
      end
      "#{ret}\n"
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

    %i(iterations url verbose a_name b_name a_example b_example width method grouper_klass).each do |sym|
      define_method(sym) { options.fetch sym }
    end
    alias_method :verbose?, :verbose

    DEFAULT_OPTIONS = {
      verbose: true,
      a_name: "Group A",
      b_name: "Group B",
      method: :get,
      iterations: 5,
      grouper_klass: Grouper::MeanGrouper
    }.freeze
  end
end
