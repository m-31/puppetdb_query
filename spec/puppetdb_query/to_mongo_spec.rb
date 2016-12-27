require "spec_helper"

# rubocop:disable Style/SpaceInsideBrackets,Style/MultilineArrayBraceLayout,Style/IndentArray
# rubocop:disable Style/MultilineHashBraceLayout
describe PuppetDBQuery::ToMongo do
  TO_MONGO_DATA = [
    [ "hostname='puppetdb-mike-217922'",
      { hostname: "puppetdb-mike-217922" }
    ],
    [ 'disable_puppet = true',
      { disable_puppet: "true" }
    ],
    [ 'fqdn~"app-dev" and group=develop and vertical~tracking and cluster_color~BLUE',
      { :$and => [
          { fqdn: { :$regex => "app-dev" } },
          { group: "develop" },
          { vertical: { :$regex => "tracking" } },
          { cluster_color: { :$regex => "BLUE" } }
        ]
      }
    ],
    [ 'fqdn~"kafka" and group=develop and vertical=tracking',
      { :$and => [
          { fqdn: { :$regex => "kafka" } },
          { group: "develop" },
          { vertical: "tracking" }
        ]
      }
    ],
    [ '(group="develop-ci" or group=develop or group=mock) and operatingsystemmajrelease="6"',
      { :$and => [
          { :$or => [
              { group: "develop-ci" },
              { group: "develop" },
              { group: "mock" }
            ]
          },
          { operatingsystemmajrelease: "6" }
        ]
      }
    ],
    [ "server_type=zoo or server_type='mesos-magr' and group!='infrastructure-ci'",
      { :$or => [
          { server_type: "zoo" },
          { :$and => [
               { server_type: "mesos-magr" },
               { group:
                   { :$ne => "infrastructure-ci" }
               }
            ]
          }
        ]
      }
    ],
    [ "server_type~'mesos-magr' and group='ops-ci' and operatingsystemmajrelease=7 and" \
      " vmtest_vm!=true and disable_puppet!=true and puppet_artifact_version!=NO_VERSION_CHECK",
      { :$and => [
          { server_type: { :$regex => "mesos-magr" } },
          { group: "ops-ci" },
          { operatingsystemmajrelease: "7" },
          { vmtest_vm: { :$ne => "true" } },
          { disable_puppet: { :$ne => "true" } },
          { puppet_artifact_version: { :$ne => "NO_VERSION_CHECK" } }
        ]
      }
    ],
    [ "server_type in [zoo, kafka]",
      { server_type:
          { :$in => [:zoo, :kafka] }
      }
    ],
  ].freeze

  TO_MONGO_DATA.each do |q, a|
    it "translates correctly #{q.inspect}" do
      expect(subject.query(q)).to eq(a)
    end
  end
end
