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

# Compatibility Matrix

|OpenStudio Common Measures Gem|OpenStudio|Ruby|
|:--------------:|:----------:|:--------:|
| 0.5.0  | 3.3      | 2.7    |
| 0.4.0 - 0,4.2 | 3.2      | 2.7    |
| 0.3.0 - 0.3.2  | 3.1      | 2.5    |
| 0.2.0 - 0.2.1  | 3.0      | 2.5    |
| 0.1.2 and below | 2.9 and below      | 2.2.4    |

# Contributing 

Please review the [OpenStudio Contribution Policy](https://openstudio.net/openstudio-contribution-policy) if you would like to contribute code to this gem.

# Releasing

* Update CHANGELOG.md
* Run `rake rubocop:auto_correct`
* Update version in `/lib/openstudio/common_measures/version.rb`
* Create PR to master, after tests and reviews complete, then merge
* Locally - from the master branch, run `rake release`
* On GitHub, go to the releases page and update the latest release tag. Name it “Version x.y.z” and copy the CHANGELOG entry into the description box.

