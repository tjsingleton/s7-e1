require "./lib/iptables"
include IPTables

describe Lexer do
  it "should detect end of string" do
    lexer = Lexer.new("")
    lexer.should be_done
    lexer.next_token.should be_nil
  end

  it "should ignore comments" do
    lexer = Lexer.new("# comment")
    lexer.next_token.should be_nil
    lexer.should be_done

    lexer = Lexer.new("# comment\nabc")
    lexer.next_token.text.should == "abc"
  end

  it "should ignore whitespace" do
    lexer = Lexer.new("    ")
    lexer.next_token.should be_nil
    lexer.should be_done

    lexer = Lexer.new(" abc")
    lexer.next_token.text.should == "abc"
  end

  {':' => :COLON,
   '*' => :SPLAT,
   '[' => :L_BRACKET,
   ']' => :R_BRACKET,
   '.' => :DOT,
   '-' => :DASH,
   '!' => :BANG,
   '"' => :D_QUOTE,
   '/' => :SLASH,
   "," => :COMMA}.each do |text, type|

    it "detects #{text} as #{type}" do
      lexer = Lexer.new(text)
      lexer.next_token.type.should == type
    end
  end

  it "detects a series of letters as WORD" do
    lexer = Lexer.new("abc")
    lexer.next_token.type.should == :WORD
  end

  it "detects a series of letters as DIGITS" do
    lexer = Lexer.new("1234")
    lexer.next_token.type.should == :DIGITS
  end
end
