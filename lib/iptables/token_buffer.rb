module IPTables
  class TokenBuffer
    def initialize(lexer, size)
      @token_buffer, @size, @tokens = lexer, size, []
      @size.times { @tokens << @token_buffer.next_token }
    end

    def [](n)
      @tokens[n]
    end

    def next_token
      token = @token_buffer.next_token
      @tokens << token if token
      @tokens.shift
    end

    def done?
      !@tokens.any?
    end
  end
end
