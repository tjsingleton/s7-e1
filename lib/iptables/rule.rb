class Rule
  attr_reader :chain, :criteria

  def initialize(options = {})
    @chain, @parts = options.values_at :chain, :criteria
    @chain.rules << self
  end
end
