module IPTables
  class Parser
    class ParserError < StandardError; end

    attr_reader :tables

    def self.parse(input)
      lexer = Lexer.new input
      new(lexer).parse
    end

    def initialize(lexer)
      @token_buffer = TokenBuffer.new(lexer, 2)
      @tables = []
    end

    def parse
      until @token_buffer.done?
        case lookahead.type
          when :SPLAT then table
          when :COLON then chain
          when :WORD  then commit
          when :DASH  then rule
        else
          error("Invalid top-level token: #{lookahead}")
        end
      end
    end

    private
    def table
      word = match(:SPLAT, :WORD)
      @tables << Table.new(word.text)
      statement_end
    end

    def chain
      Chain.new(table:      @tables.last || error("Table required for a chain"),
                name:       match(:COLON, :WORD).text,
                policy:     alternations(:WORD, :DASH).text,
                packets_in: match(:L_BRACKET, :DIGITS).text.to_i,
                bytes_in:   match(:COLON, :DIGITS).text.to_i)

      match(:R_BRACKET) && statement_end
    end

    def commit
      match(:WORD) && statement_end
    end

    def rule
      command    = match(:DASH, :WORD) # should always be append
      chain_name = match(:WORD).text

      chain      = @tables.last.chains[chain_name]
      error("Chain required for rule") unless chain

      criteria = []
      until statement_end?
        criteria << [rule_key, rule_value]
      end

      Rule.new(chain:    chain,
               command:  command.text, # TODO Run through options normalizer
               criteria: Hash[criteria])

      statement_end
    end

    def rule_key
      parts = []

      match(:DASH) && optional(:DASH)

      loop do
        parts << match(:WORD).text
        break unless optional(:DASH)
      end

      parts.join("-") # TODO Run through options normalizer
    end

    def rule_value
      tokens = []
      until rule_end?
        tokens << parse_value
      end
      tokens
    end

    def rule_end?
      statement_end? || expect(:DASH)
    end

    def parse_value
      case
        when expect(:COMMA, 1)                    then list
        when expect(:DIGITS) && expect(:DOT, 1)   then ip_address
        when expect(:DIGITS) && expect(:COLON, 1) then port_range
        when expect(:DIGITS) && expect(:SLASH, 1) then time_limit
        when expect(:DIGITS)                      then match(:DIGITS).text
        when expect(:WORD)                        then match(:WORD).text
        when expect(:BANG)                        then match(:BANG).text
      else
        error "Unexpected token sequence: #{lookahead}, #{lookahead(1)}"
      end
    end

    def list
      parts = []
      loop do
        parts << match(:WORD).text
        break unless optional(:COMMA)
      end
      parts
    end


    def ip_address
      parts = []

      4.times do
        parts << match(:DIGITS).text
        match(:DOT) if expect(:DOT)
      end

      parts.join(".")
    end

    def port_range
      from = match(:DIGITS).text.to_i
      to   = match(:COLON) && match(:DIGITS).text.to_i

      (from..to)
    end

    # TODO think of a better way to represent
    TimeLimit = Struct.new(:quantity, :division) do
      define_method(:to_s) do
        "#{quanitity}/#{division}"
      end
    end

    def time_limit
      quantity = match(:DIGITS)
      division = match(:SLASH) && match(:WORD)
      TimeLimit.new(quantity, division)
    end

    def statement_end?
      @token_buffer.done? || expect(:NEW_LINE)
    end

    def statement_end
      @token_buffer.done? || match(:NEW_LINE)
    end

    def expect(sym, n = 0)
      lookahead(n) && lookahead(n).type == sym
    end

    def match(*types)
      types.map do |type|
        lookahead_type = lookahead && lookahead.type

        if lookahead_type == type
          current = lookahead
          @token_buffer.next_token
          current
        else
          error "expecting #{type}; found #{lookahead_type}"
        end
      end.last
    end

    def optional(sym)
      match(sym) if expect(sym)
    end

    def alternations(*types)
      if types.include? lookahead.type
        match lookahead.type
      else
        error "expecting #{types.join(", ")}; found #{lookahead.type}"
      end
    end

    def lookahead(n = 0)
      @token_buffer[n]
    end

    def error(message)
      raise ParserError, message
    end
  end
end
