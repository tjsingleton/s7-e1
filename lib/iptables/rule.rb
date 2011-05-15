class Rule
  attr_reader :chain, :options

  def initialize(chain, options = {})
    @chain, @options = chain, options
  end
end
