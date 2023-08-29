# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'fileutils'

require 'minitest/autorun'

class ViewModel_Test < MiniTest::Unit::TestCase
  # paths to expected test files, includes osm and eplusout.sql
  def modelPath
    # return "#{File.dirname(__FILE__)}/SimpleModel.osm"
    return "#{File.dirname(__FILE__)}/ExampleModel.osm"
    # return "#{File.dirname(__FILE__)}/RotationTest.osm"
  end

  def reportPath
    return "#{File.dirname(__FILE__)}/output/report.json"
  end

  # create test files if they do not exist
  def setup
    if File.exist?(reportPath)
      FileUtils.rm(reportPath)
    end

    assert(File.exist?(modelPath))
  end

  # delete output files
  def teardown
    # comment this out if you want to see the resulting report
    if File.exist?(reportPath)
      # FileUtils.rm(reportPath())
    end
  end

  # the actual test
  def test_ViewModel_withoutGeometryDiagnostics
    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    assert(File.exist?(modelPath))
    model = translator.loadModel(modelPath)
    assert(!model.empty?)
    model = model.get

    # create an instance of the measure
    measure = ViewModel.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
    assert_equal('use_geometry_diagnostics', arguments[0].name)
    assert_equal(false, arguments[0].defaultValueAsBool)

    current_dir = Dir.pwd
    run_dir = File.dirname(__FILE__) + '/output/withoutGeometryDiagnostics'
    FileUtils.rm_rf(run_dir) if File.exist?(run_dir)
    FileUtils.mkdir_p(run_dir)
    Dir.chdir(run_dir)

    # set argument values to good values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'NA')
    assert(result.warnings.empty?)
    # assert(result.info.size == 1)

    Dir.chdir(current_dir)

    assert(File.exist?(reportPath))

    # load the output in http://threejs.org/editor/ to test
  end

  # the actual test
  def test_ViewModel_withGeometryDiagnostics

    if Gem::Version.new(OpenStudio.openStudioVersion) <= Gem::Version.new('3.6.1')
      return
    end

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    assert(File.exist?(modelPath))
    model = translator.loadModel(modelPath)
    assert(!model.empty?)
    model = model.get

    # create an instance of the measure
    measure = ViewModel.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # get arguments and test that they are what we are expecting
    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash['use_geometry_diagnostics'] = true
    # using defaults values from measure.rb for other arguments

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    current_dir = Dir.pwd
    run_dir = File.dirname(__FILE__) + '/output/withGeometryDiagnostics'
    FileUtils.rm_rf(run_dir) if File.exist?(run_dir)
    FileUtils.mkdir_p(run_dir)
    Dir.chdir(run_dir)

    # set argument values to good values and run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'NA')
    assert(result.warnings.empty?)
    # assert(result.info.size == 1)

    Dir.chdir(current_dir)

    assert(File.exist?(reportPath))

    # load the output in http://threejs.org/editor/ to test
  end

end
