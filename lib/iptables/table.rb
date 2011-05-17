module IPTables
  class Table
    attr_reader :name, :chains

    def initialize(name)
      @name, @chains = name, {}
    end

    def to_s
      "<Table: #{@name}>"
    end
  end
end
