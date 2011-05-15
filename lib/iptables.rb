require "iptables/lexer"
require "iptables/token_buffer"
require "iptables/parser"
require "iptables/table"
require "iptables/chain"
require "iptables/rule"

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
