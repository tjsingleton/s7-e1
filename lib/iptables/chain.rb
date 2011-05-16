class Chain
  attr_reader :table, :name, :rules, :policy, :packets_in, :bytes_in

  def initialize(options = {})
    @name       = options[:name]
    @policy     = options[:policy]
    @packets_in = options[:packets_in]
    @bytes_in   = options[:bytes_in]

    @table = options[:table]
    @table.chains[@name] = self

    @rules = []
  end

  def to_s
    "<Chain: #{@name}>"
  end
end
