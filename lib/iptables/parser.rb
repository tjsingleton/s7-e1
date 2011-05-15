module IPTables
  class Parser
    class ParserError < StandardError; end

    attr_reader :tables

    def self.parse(input)
      lexer = Lexer.new input
      new(lexer).parse
    end

    def initialize(lexer)
      @token_buffer = TokenBuffer.new(lexer, 1)
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
      match(:DASH, :WORD) # command - should always be append
      chain_name = match(:WORD).text

      chain      = @tables.last.chains[chain_name]
      error("Chain required for rule") unless chain

      parts = []
      until statement_end?
        parts << [rule_key, rule_value]
      end

      statement_end
    end

    def rule_key
      match(:DASH) && optional(:DASH)
      match(:WORD).text
    end

    def rule_value
      tokens = []
      until statement_end? || expect(:DASH)
        tokens << parse_value
      end
    end

    def parse_value
      advance
    end

    def statement_end?
      @token_buffer.done? || expect(:NEW_LINE)
    end

    def statement_end
      @token_buffer.done? || match(:NEW_LINE)
    end

    def expect(sym)
      lookahead && lookahead.type == sym
    end

    def match(*types)
      types.map do |type|
        lookahead_type = lookahead && lookahead.type

        if lookahead_type == type
          current = lookahead
          advance
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

    def advance
      @token_buffer.next_token
    end

    def lookahead(n = 0)
      @token_buffer[n]
    end

    def error(message)
      raise ParserError, message
    end
  end
end
