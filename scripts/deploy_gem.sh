#!/bin/bash

# release puppetdb_query gem to rubygems

# exit on any error
set -e

#############################################################################
## defaults

readonly progname=$(basename $0)
readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
readonly main_dir=$( cd "${script_dir}" && cd .. && pwd )
readonly application=puppetdb_query
readonly module=PuppetDBQuery

#############################################################################
## functions

## write green message with time stamp to stdout
function puts () {
  echo -e "\033[0;32m"$(date +"%Y-%m-%d %T") $*"\033[0m"
}

## bump version, must be in main git directory
function bump_version () {
  puts "bump ${application} gem version"

  old_version=$( ruby -I lib/${application} -e "require 'version'; puts Gem::Version.new(${module}::VERSION)" )
  puts "gem version currently:" ${old_version}

  new_version=$( ruby -I lib/${application} -e "require 'version'; puts Gem::Version.new(${module}::VERSION + '.1').bump" )
  puts "we will change it into:" ${new_version}

  cat lib/${application}/version.rb | sed "s/$old_version/$new_version/" > lib/${application}/version.rb.new
  mv lib/${application}/version.rb.new lib/${application}/version.rb
}

## commit and push version, must be in main git directory
function commit_and_push_version () {
  puts "commit and push ${application} gem version"
  git add Gemfile.lock lib/${application}/version.rb
  git commit -m "m31's version bumper"
  git push
}

#############################################################################
## main processsing

cd ${main_dir}

puts "trying to release ${application} gem to rubygems"
puts

puts "updating git repository"
git pull -r

puts "build new Gemfile.lock with bundle install"
rm Gemfile.lock
bundle install

puts "check and test"
bundle exec rake spec

bump_version
commit_and_push_version

puts "build gem"
result=$( gem build ${application}.gemspec )
puts "  ${result}"

# get gem file name
set +e
gem_file=$( echo $result | grep -o "${application}-[.0-9]*\.gem$" )
set -e
puts "  gem file:" $gem_file

## check if group was specified
if [ -z "${gem_file}" ]; then
    echo "generated gem file not found" >&2
    exit 1
fi

puts "push gem to rubygems"
gem push ${gem_file} --host https://rubygems.org

echo -e "\033[0;34mThe lioness has rejoined her cub, and all is right in the jungle...\033[0m"
