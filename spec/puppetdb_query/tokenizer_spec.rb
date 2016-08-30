require "spec_helper"

describe PuppetDBQuery::Tokenizer do
  DATA = [
    [ 'hostname=\'puppetdb-mike-217922\'',
      [:hostname, :equal, "puppetdb-mike-217922"]
    ],
    [ 'disable_puppet = true',
      [:disable_puppet, :equal, :true]
    ],
    [ 'fqdn~"app-dev" and group=develop and vertical~tracking and cluster_color~BLUE',
      [:fqdn, :match, "app-dev", :and, :group, :equal, :develop, :and, :vertical, :match, :tracking, :and, :cluster_color, :match, :BLUE]
    ],
    [ 'fqdn~"kafka" and group=develop and vertical=tracking',
      [:fqdn, :match, "kafka", :and, :group, :equal, :develop, :and, :vertical, :equal, :tracking]
    ],
    [ '(group="develop-ci" or group=develop or group=mock) and (operatingsystemmajrelease="6")',
      [:begin, :group, :equal, "develop-ci", :or, :group, :equal, :develop, :or, :group, :equal, :mock, :end, :and, :begin, :operatingsystemmajrelease, :equal, "6", :end]
    ],
    [ "server_type=zoo or server_type='mesos-magr') and group!='infrastructure-ci'",
      [:server_type, :equal, :zoo, :or, :server_type, :equal, "mesos-magr", :end, :and, :group, :not_equal, "infrastructure-ci"]
    ],
    [ "server_type~'mesos-magr' and group='ops-ci' and operatingsystemmajrelease=7 and vmtest_vm!=true and disable_puppet!=true and puppet_artifact_verion!=NO_VERSION_CHECK",
      [:server_type, :match, "mesos-magr", :and, :group, :equal, "ops-ci", :and, :operatingsystemmajrelease, :equal, 7, :and, :vmtest_vm, :not_equal, :true, :and, :disable_puppet, :not_equal, :true, :and, :puppet_artifact_verion, :not_equal, :NO_VERSION_CHECK]
    ],
  ]

  DATA.each do |q, a|
    describe "translates correctly #{q.inspect}" do
      subject { PuppetDBQuery::Tokenizer.new(q) }
      it "into tokens" do
        expect(subject.map { |n| n }).to eq(a)
      end
     end
  end
end
