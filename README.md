### Description

This library provides a recursive decent parser for the output of `iptables-save`. It provides the means in which you can access these rules in typical ruby objects. Future work on these objects could allow you to convert these objects back into the format for use with `iptables-restore`.

### Documentation

The [IPTables::from_save](https://github.com/tjsingleton/s7-e1/blob/master/lib/iptables.rb#L12) is the standard entry point returning an array of [table objects](https://github.com/tjsingleton/s7-e1/blob/master/lib/iptables/table.rb). IPTables::Table#chains provides a hash of [chain objects](https://github.com/tjsingleton/s7-e1/blob/master/lib/iptables/chain.rb). IPTables::Chain#rules provides an array of [rule objects](https://github.com/tjsingleton/s7-e1/blob/master/lib/iptables/rule.rb). IPTables::Rule#criteria is a hash containing the rule descriptions.

This library has only been tested on Ruby 1.9.2.

### Examples

#### Parsing direct from iptables:

    tables = IPTables.from_save

#### Parsing from a file:

    source = File.open('samples/iptables-save.1').read
    tables = IPTables::Parser.parse(source)

#### Traversing the tree:

    tables = IPTables.from_save
    filter = tables.detect{|table| table.name == 'filter' }
    input  = filter.chains["INPUT"]
    rule   = input.rules.first
    rule.criteria
    # => {"in-interface"=>["eth1"], "jump"=>["ACCEPT"]}

### Questions and/or Comments

Feel free to email [TJ Singleton](tjsingleton@vantagestreet.com) with any questions.
