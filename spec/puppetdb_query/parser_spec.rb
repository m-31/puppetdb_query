require "spec_helper"

# rubocop:disable Style/SpaceInsideBrackets,Style/MultilineArrayBraceLayout
# rubocop:disable Style/MultilineMethodCallIndentation,Style/RedundantParentheses
# rubocop:disable Style/ClosingParenthesisIndentation,Metrics/BlockLength
describe PuppetDBQuery::Parser do
  CORRECT_PARSER_DATA = [
    [ 'hostname=\'puppetdb-mike-217922\'',
      [PuppetDBQuery::Term.new(PuppetDBQuery::Parser::EQUAL).add(:hostname, "puppetdb-mike-217922")]
    ],
    [ 'disable_puppet = true',
      [PuppetDBQuery::Term.new(PuppetDBQuery::Parser::EQUAL).add(:disable_puppet, true)]
    ],
    [ 'fqdn~"app-dev" and group=develop and vertical~tracking and cluster_color~BLUE',
      [PuppetDBQuery::Term.new(PuppetDBQuery::Parser::AND)
         .add(PuppetDBQuery::Term.new(PuppetDBQuery::Parser::MATCH).add(:fqdn, "app-dev"))
         .add(PuppetDBQuery::Term.new(PuppetDBQuery::Parser::EQUAL).add(:group, :develop))
         .add(PuppetDBQuery::Term.new(PuppetDBQuery::Parser::MATCH).add(:vertical, :tracking))
         .add(PuppetDBQuery::Term.new(PuppetDBQuery::Parser::MATCH).add(:cluster_color, :BLUE))
      ]
    ],
    [ 'a~"A" and g=G or v~t and c~B',
      [PuppetDBQuery::Term.new(PuppetDBQuery::Parser::OR)
        .add((PuppetDBQuery::Term.new(PuppetDBQuery::Parser::AND)
          .add(PuppetDBQuery::Term.new(PuppetDBQuery::Parser::MATCH).add(:a, "A"))
          .add(PuppetDBQuery::Term.new(PuppetDBQuery::Parser::EQUAL).add(:g, :G))
         )).add((PuppetDBQuery::Term.new(PuppetDBQuery::Parser::AND)
          .add(PuppetDBQuery::Term.new(PuppetDBQuery::Parser::MATCH).add(:v, :t))
          .add(PuppetDBQuery::Term.new(PuppetDBQuery::Parser::MATCH).add(:c, :B))
         ))
      ]
    ],
    [ 'type in [jenkins, mongo, tomcat]',
      [PuppetDBQuery::Term.new(PuppetDBQuery::Parser::IN)
        .add(:type, [:jenkins, :mongo, :tomcat])
      ]
    ],
    [ 'type is null',
      [PuppetDBQuery::Term.new(PuppetDBQuery::Parser::EQUAL).add(:type, :null)]
    ],
    [ '(type is null)',
      [PuppetDBQuery::Term.new(PuppetDBQuery::Parser::EQUAL).add(:type, :null)]
    ],
  ].freeze

  CORRECT_PARSER_DATA.each do |q, a|
    it "translates correctly #{q.inspect}" do
      expect(subject.parse(q)).to eq(a)
    end
  end

  it "complains about missing )" do
    expect { subject.parse("a!=true and (b=false") }.to raise_error(/'\)' expected/)
  end

  it "complains about missing arguments for and" do
    expect { subject.parse("a!=true and") }.to raise_error(/to few arguments for operator 'and'/)
  end

  it "complains about missing arguments for not" do
    expect { subject.parse("not") }.to raise_error(/prefix operator 'not' got no argument/)
  end

  it "complains about closing bracket" do
    expect { subject.parse(")") }.to raise_error(/that was not expected here: '\)'/)
  end

  it "complains about closing bracket 2" do
    expect { subject.parse("not )") }.to raise_error(/that was not expected here: '\)'/)
  end
end
