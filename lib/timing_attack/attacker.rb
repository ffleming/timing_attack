module TimingAttack
  module Attacker
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
