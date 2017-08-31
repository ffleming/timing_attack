module TimingAttack
  module Errors
    BruteForcerError = Class.new(StandardError)
    InvalidFileFormatError = Class.new(StandardError)
    FileNotFoundError = Class.new(StandardError)
  end
end
