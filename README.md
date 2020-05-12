# OpenStudio Common Measures 

Common measures used by OpenStudio.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openstudio-common-measures'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install 'openstudio-common-measures'

## Tests

To run the tests similar to how Jenkins run:

```
bundle install

bundle exec rake
bundle exec rake openstudio:list_measures
bundle exec rake openstudio:update_measures
bundle exec rake openstudio:test_with_openstudio
```
## TODO

- [ ] Update measures to follow coding standards

# Releasing

* Update CHANGELOG.md
* Run `rake rubocop:auto_correct`
* Update version in `/lib/openstudio/common_measures/version.rb`
* Create PR to master, after tests and reviews complete, then merge
* Locally - from the master branch, run `rake release`
* On GitHub, go to the releases page and update the latest release tag. Name it “Version x.y.z” and copy the CHANGELOG entry into the description box.

