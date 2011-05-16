require "strscan"

module IPTables
  class Lexer
    class LexerError < StandardError; end

    SYMBOLS = {
        '#'  => :POUND,
        " "  => :SPACE,
        ':'  => :COLON,
        '*'  => :SPLAT,
        '['  => :L_BRACKET,
        ']'  => :R_BRACKET,
        '.'  => :DOT,
        '-'  => :DASH,
        '!'  => :BANG,
        '"'  => :D_QUOTE,
        '/'  => :SLASH,
        ","  => :COMMA,
        "\n" => :NEW_LINE
    }

    def initialize(input)
      @scanner = StringScanner.new input
    end

    def next_token
      case type = get_type
        when :POUND     then comment
        when :SPACE     then whitespace
        when :DIGIT     then digits
        when :LETTER    then word
        when :D_QUOTE   then quote
        when :COLON, :SPLAT, :R_BRACKET, :L_BRACKET, :DOT, :DASH, :BANG,
             :SLASH, :COMMA, :NEW_LINE
          token type
      else
        raise(LexerError, "Invalid token: #{lookahead}") unless done?
      end
    end

    def done?
      @scanner.eos?
    end

    private
    def lookahead
      @scanner.peek 1
    end

    def advance
      @scanner.getch
    end

    def get_type
      case _lookahead = lookahead
        when _lookahead[/[a-zA-Z_]/, 0] then :LETTER
        when _lookahead[/\d/, 0]        then :DIGIT
      else
        SYMBOLS[_lookahead]
      end
    end

    def comment
      until done? || advance == "\n"; end
      next_token
    end

    def whitespace
      @scanner.scan /[ ]+/
      next_token
    end

    def word
      text = @scanner.scan /^[a-zA-Z_][a-zA-Z_0-9]{0,}/
      text && Token.new(:WORD, text)
    end

    def quote
      advance # skip first quote
      text = @scanner.scan_until(/"/)
      raise(LexerError, "Missing closing quote") unless text
      without_last_quote = text[0, text.length-1]
      Token.new(:WORD, without_last_quote)
    end

    def digits
      text = @scanner.scan /[\d]+/
      text && Token.new(:DIGITS, text)
    end

    def token(sym)
      Token.new(sym, advance)
    end

    Token = Struct.new(:type, :text) do
      define_method :to_s do
        "<Token:#{type} #{text}>"
      end
    end
  end
end
