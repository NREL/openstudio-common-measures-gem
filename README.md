# OpenStudio(R) Common Measures 

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
| 0.12.0         | 3.10      | 3.2.2    |
| 0.11.1         | 3.9      | 3.2.2    |
| 0.11.0         | 3.9      | 3.2.2    |
| 0.10.0         | 3.8      | 3.2.2    |
| 0.9.0         | 3.7      | 2.7    |
| 0.8.0         | 3.6      | 2.7    |
| 0.7.0         | 3.5      | 2.7    |
| 0.6.0 - 0.6.1 | 3.4      | 2.7    |
| 0.5.0  | 3.3      | 2.7    |
| 0.4.0 - 0,4.2 | 3.2      | 2.7    |
| 0.3.0 - 0.3.2  | 3.1      | 2.5    |
| 0.2.0 - 0.2.1  | 3.0      | 2.5    |
| 0.1.2 and below | 2.9 and below      | 2.2.4    |

# Contributing 

Please review the [OpenStudio Contribution Policy](https://openstudio.net/openstudio-contribution-policy) if you would like to contribute code to this gem.

# Releasing

* Update `CHANGELOG.md` with the `rake openstudio:change_log` command
* Run `rake openstudio:rubocop:auto_correct`
* Run `rake openstudio:update_copyright`
* Run `rake openstudio:update_measures` (this has to be done last since prior tasks alter measure files)
* Update version in `readme.md`
* Update version in `openstudio-common_measures.gemspec`
* Update version in `/lib/openstudio/common_measures/version.rb`
* Create PR to master, after tests and reviews complete, then merge
* Locally - from the master branch, run `rake release`
* On GitHub, go to the releases page and update the latest release tag. Name it “Version x.y.z” and copy the CHANGELOG entry into the description box.

