require "spec_helper"

describe PuppetDBQuery::ToMongo do
  DATA = [
    [ 'hostname=\'puppetdb-mike-217922\'',
      {:hostname=>"puppetdb-mike-217922"}
    ],
    [ 'disable_puppet = true',
      {:disable_puppet=>:true}
    ],
    [ 'fqdn~"app-dev" and group=develop and vertical~tracking and cluster_color~BLUE',
      {:$and=>[{:$and=>[{:$and=>[{:fqdn=>{:$regex=>"app-dev"}}, {:group=>:develop}]}, {:vertical=>{:$regex=>"tracking"}}]}, {:cluster_color=>{:$regex=>"BLUE"}}]}
    ],
    [ 'fqdn~"kafka" and group=develop and vertical=tracking',
      {:$and=>[{:$and=>[{:fqdn=>{:$regex=>"kafka"}}, {:group=>:develop}]}, {:vertical=>:tracking}]}
    ],
    [ '(group="develop-ci" or group=develop or group=mock) and (operatingsystemmajrelease="6")',
      {:$and=>[{:$or=>[{:$or=>[{:group=>"develop-ci"}, {:group=>:develop}]}, {:group=>:mock}]}, {:operatingsystemmajrelease=>"6"}]}
    ],
    [ "server_type=zoo or server_type='mesos-magr') and group!='infrastructure-ci'",
      {:$or=>[{:server_type=>:zoo}, {:server_type=>"mesos-magr"}]}
    ],
  ]

  DATA.each do |q, a|
    it "translates correctly #{q.inspect}" do
      expect(subject.query(q)).to eq(a)
     end
  end
end
