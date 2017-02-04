module TimingAttack
  class Spinner

    STATES = %w(| / - \\)
    def increment
      @spinner_i ||= 0
      @spinner_i += 1
      print "\r #{SPINNER[@spinner_i % SPINNER.length]}"
    end
  end
end

