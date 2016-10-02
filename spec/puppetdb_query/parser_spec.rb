require "spec_helper"

# rubocop:disable Style/SpaceInsideBrackets,Style/MultilineArrayBraceLayout
# rubocop:disable Style/MultilineMethodCallIndentation,Style/RedundantParentheses
# rubocop:disable Style/ClosingParenthesisIndentation
describe PuppetDBQuery::Parser do
  PARSER_DATA = [
    [ 'hostname=\'puppetdb-mike-217922\'',
      [PuppetDBQuery::Term.new(PuppetDBQuery::Parser::EQUAL).add(:hostname, "puppetdb-mike-217922")]
    ],
    [ 'disable_puppet = true',
      [PuppetDBQuery::Term.new(PuppetDBQuery::Parser::EQUAL).add(:disable_puppet, :true)]
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
  ].freeze

  PARSER_DATA.each do |q, a|
    it "translates correctly #{q.inspect}" do
      expect(subject.parse(q)).to eq(a)
    end
  end
end
