#
# ActiveFacts tests: Test the CQL parser by looking at its parse trees.
# Copyright (c) 2008 Clifford Heath. Read the LICENSE file.
#

require 'activefacts/cql'
require 'activefacts/support'
require 'activefacts/api/support'
require 'helpers/test_parser'

describe "Fact Types" do
  FactTypes = [
    [ "Foo has at most one Bar, Bar is of one Foo restricted to {1..10};",
      ["FactType: [{Foo} \"has\" {[..1] Bar}, {Bar} \"is of\" {[1..1] Foo ValueConstraint to ([1..10])}]"]
    ],
    [ "Bar(1) is related to Bar(2), primary-Bar(1) has secondary-Bar(2);",
      ["FactType: [{Bar(1)} \"is related to\" {Bar(2)}, {primary- Bar(1)} \"has\" {secondary- Bar(2)}]"]
    ],
    # REVISIT: Test all quantifiers
    # REVISIT: Test all post-qualifiers
    [ "AnnualIncome is where Person has total- Income in Year: Person has total- Income.sum(), Income was earned in current- Time.Year() (as Year);",
      ["FactType: AnnualIncome [{Person} \"has\" {total- Income} \"in\" {Year}] where {Person} \"has\" {total- Income}, {Income} \"was earned in\" {current- Time (as Year)}"]
    ],
    [ "A is interesting : b- C has F -g;",
      ["FactType: [{A} \"is interesting\"] where {b- C} \"has\" {F -g}"]
    ]
  ]

  before :each do
    @parser = TestParser.new
  end

  FactTypes.each do |c|
    source, ast, definition = *c
    it "should parse #{source.inspect}" do
      result = @parser.parse_all(source, :definition)

      puts @parser.failure_reason unless result

      #result = [result[-1]]
      canonical_form = result.map{|d| d.ast.to_s}
      if ast
        canonical_form.should == ast
      else
        puts "#{source.inspect} should compile to"
        puts "\t#{canonical_form}"
      end
    end
  end
end