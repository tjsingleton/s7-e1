require_relative "../lib/iptables"
include IPTables

describe Parser do
  it "can parse a table" do
    lexer = Lexer.new "*name"
    parser = Parser.new(lexer)
    parser.parse
    parser.tables.first.name.should == "name"
  end

  it "appends chains to the table" do
    lexer = Lexer.new "*name\n:PREROUTING ACCEPT [85981841:29410361593]\n"
    parser = Parser.new(lexer)
    parser.parse

    chain = parser.tables.first.chains["PREROUTING"]
    chain.name.should == "PREROUTING"
    chain.packets_in.should == 85981841
    chain.bytes_in.should == 29410361593
  end
end

describe Parser, "example set without rules" do
  let(:source) { File.open('samples/iptables-save.2').read }
  let(:lexer)  { Lexer.new source }
  let(:parser) { Parser.new lexer }

  before(:all) { parser.parse }

  it("should have when to the end") { lexer.should be_done }

  it "has 5 tables: security, raw, nat, mangle, and filter" do
    parser.tables.length.should == 5
    names = parser.tables.map(&:name)
    (names - %w[security raw nat mangle filter]).should be_empty
  end

  {"security" => [["INPUT",   "ACCEPT", 150659451, 11738985285],
                  ["FORWARD", "ACCEPT", 0,         0],
                  ["OUTPUT",  "ACCEPT", 136187431, 8974404828]],

   "raw"      => [["PREROUTING", "ACCEPT", 150659466, 11738989605],
                  ["OUTPUT",     "ACCEPT", 136187432, 8974404872]],

   "nat"      => [["PREROUTING",  "ACCEPT", 808887, 87552431],
                  ["POSTROUTING", "ACCEPT", 39064,  2583206],
                  ["OUTPUT",      "ACCEPT", 39064,  2583206]],

   "mangle"   => [["PREROUTING",  "ACCEPT", 150659466, 11738989605],
                  ["INPUT",       "ACCEPT", 150659451, 11738985285],
                  ["FORWARD",     "ACCEPT", 0,         0],
                  ["OUTPUT",      "ACCEPT", 136187431, 8974404828],
                  ["POSTROUTING", "ACCEPT", 136187431, 8974404828]],

   "filter"   => [["INPUT",       "ACCEPT", 150659451, 11738985285],
                  ["FORWARD",     "ACCEPT", 0,         0],
                  ["OUTPUT",      "ACCEPT", 136187431, 8974404828]]
  }.each do |table_name, chains|

    context "Table: #{table_name}" do
      before do
        @table = parser.tables.detect {|table| table.name == table_name }
      end

      it("should not be nil") { @table.should_not be_nil }

      chains.each do |chain_name, policy, packets_in, bytes_in|
        context "Chain: #{chain_name}" do
          subject { @table.chains[chain_name] }

          it { should_not be_nil}

          its(:name)       { should == chain_name }
          its(:policy)     { should == policy }
          its(:packets_in) { should == packets_in }
          its(:bytes_in)   { should == bytes_in }
        end
      end
    end

  end
end

describe Parser, "example set with rules" do
  let(:source) { File.open('samples/iptables-save.1').read }
  let(:lexer)  { Lexer.new source }
  let(:parser) { Parser.new lexer }

  before(:all) { parser.parse }

  it("should have when to the end") { lexer.should be_done }
end
