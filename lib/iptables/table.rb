class Table
  attr_reader :name, :chains

  def initialize(name)
    @name, @chains = name, {}
  end
end
