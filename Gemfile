source "http://rubygems.org"

# Specify your gem's dependencies in openstudio-model-articulation.gemspec
gemspec

if File.exists?('../openstudio-extension-gem')
  # gem 'openstudio-extension', github: 'NREL/openstudio-extension-gem', branch: 'develop'
  gem 'openstudio-extension', path: '../openstudio-extension-gem'
else
  gem 'openstudio-extension', github: 'NREL/openstudio-extension-gem', branch: 'develop'
end

# simplecov has an unneccesary dependency on native json gem, use fork that does not require this
gem 'simplecov', github: 'NREL/simplecov'