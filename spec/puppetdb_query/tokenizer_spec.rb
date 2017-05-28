require "spec_helper"

# rubocop:disable Style/SpaceInsideBrackets,Style/MultilineArrayBraceLayout
# rubocop:disable Metrics/BlockLength
describe PuppetDBQuery::Tokenizer do
  TOKENIZER_DATA = [
    [ 'hostname=\'puppetdb-mike-217922\'',
      [:hostname, :_equal, "puppetdb-mike-217922"]
    ],
    [ 'disable_puppet = true',
      [:disable_puppet, :_equal, true]
    ],
    [ 'fqdn~"app-dev" and group=develop and vertical~tracking and cluster_color~BLUE',
      [:fqdn, :_match, "app-dev", :_and, :group, :_equal, :develop, :_and, :vertical, :_match,
       :tracking, :_and, :cluster_color, :_match, :BLUE]
    ],
    [ 'fqdn~"kafka" and group=develop and vertical=tracking',
      [:fqdn, :_match, "kafka", :_and, :group, :_equal, :develop, :_and, :vertical, :_equal,
       :tracking]
    ],
    [ '(group="develop-ci" or group=develop or group=mock) and (operatingsystemmajrelease="6")',
      [:_begin, :group, :_equal, "develop-ci", :_or, :group, :_equal, :develop, :_or, :group,
       :_equal, :mock, :_end, :_and, :_begin, :operatingsystemmajrelease, :_equal, "6", :_end]
    ],
    [ "server_type=zoo or server_type='mesos-magr') and group!='infrastructure-ci'",
      [:server_type, :_equal, :zoo, :_or, :server_type, :_equal, "mesos-magr", :_end, :_and,
       :group, :_not_equal, "infrastructure-ci"]
    ],
    [ "server_type~'mesos-magr' and group='ops-ci' and operatingsystemmajrelease=7 and" \
      " vmtest_vm!=true and disable_puppet!=true and puppet_artifact_version!=NO_VERSION_CHECK",
      [:server_type, :_match, "mesos-magr", :_and, :group, :_equal, "ops-ci", :_and,
       :operatingsystemmajrelease, :_equal, 7, :_and, :vmtest_vm, :_not_equal, true, :_and,
       :disable_puppet, :_not_equal, true, :_and, :puppet_artifact_version, :_not_equal,
       :NO_VERSION_CHECK]
    ],
  ].freeze

  TOKENIZER_DATA.each do |q, a|
    describe "translates correctly #{q.inspect}" do
      subject { PuppetDBQuery::Tokenizer.new(q) }
      it "into tokens" do
        expect(subject.map { |n| n }).to eq(a)
      end
    end
  end
end
