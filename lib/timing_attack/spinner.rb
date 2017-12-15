module TimingAttack
  class Spinner

    STATES = %w(| / - \\)
    def increment
      @_spinner ||= 0
      print "\r #{STATES[@_spinner % STATES.length]}"
      @_spinner += 1
      @_spinner = 0 if @_spinner >= STATES.length
    end
  end
end

