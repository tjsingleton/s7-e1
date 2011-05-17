require_relative "iptables/lexer"
require_relative "iptables/token_buffer"
require_relative "iptables/parser"
require_relative "iptables/table"
require_relative "iptables/chain"
require_relative "iptables/rule"

module IPTables
  class IPTableError < StandardError; end

  # returns the tables parsed from `iptables-save`
  def from_save
    unless `which iptables-save`.present?
      raise IPTableError, "Could not locate iptables-save"
    end

    Parser.parse(`iptables-save`).tables
  end
end
