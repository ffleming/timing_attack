module TimingAttack
  class Spinner

    STATES = %w(| / - \\)
    def increment
      @spinner_i ||= 0
      @spinner_i += 1
      print "\r #{STATES[@spinner_i % STATES.length]}"
    end
  end
end

