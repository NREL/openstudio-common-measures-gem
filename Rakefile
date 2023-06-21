# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# Load in the rake tasks from the base extension gem
require 'openstudio/extension/rake_task'
require 'openstudio/common_measures'
rake_task = OpenStudio::Extension::RakeTask.new
rake_task.set_extension_class(OpenStudio::CommonMeasures::Extension, 'nrel/openstudio-common-measures-gem')

require 'openstudio_measure_tester/rake_task'
OpenStudioMeasureTester::RakeTask.new

task default: :spec

desc 'Delete measure test output'
task :delete_measure_test_outputs do
  require 'fileutils'

  puts 'Deleting tests/output directory from measures.'

  # get measures in repo
  measures = Dir.glob('**/**/**/measure.rb')

  #create unique list of parent directories for measures.
  measures.each do |i|
    FileUtils.rm_rf(i.gsub("measure.rb","tests/output"))
  end
  puts "Deleted test outputs"

end
