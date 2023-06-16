# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class TariffSelectionTimeAndDateDependant_Test < Minitest::Test
  # def setup
  # end

  # def teardown

  def test_good_argument_values
    # create an instance of the measure
    measure = TariffSelectionTimeAndDateDependant.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['summer_start_month'] = 5
    args_hash['summer_start_day'] = 1
    args_hash['summer_end_month'] = 9
    args_hash['summer_end_day'] = 1
    args_hash['peak_start_hour'] = 12
    args_hash['peak_end_hour'] = 18

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # save the workspace to output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_output.idf')
    workspace.save(output_file_path, true)
  end

  def test_good_argument_values_full_hour
    # create an instance of the measure
    measure = TariffSelectionTimeAndDateDependant.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['demand_window_length'] = 'FullHour'
    args_hash['summer_start_month'] = 5
    args_hash['summer_start_day'] = 1
    args_hash['summer_end_month'] = 9
    args_hash['summer_end_day'] = 1
    args_hash['peak_start_hour'] = 12
    args_hash['peak_end_hour'] = 18

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # save the workspace to output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_output.idf')
    # workspace.save(output_file_path,true)
  end

  def test_good_argument_values_time_step_3
    # create an instance of the measure
    measure = TariffSelectionTimeAndDateDependant.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # alter timestep vs. keeping a second OSM model around
    workspace.getObjectsByType('Timestep'.to_IddObjectType)[0].setString(0, '3')

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['summer_start_month'] = 5
    args_hash['summer_start_day'] = 1
    args_hash['summer_end_month'] = 9
    args_hash['summer_end_day'] = 1
    args_hash['peak_start_hour'] = 12
    args_hash['peak_end_hour'] = 18

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # save the workspace to output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_output.idf')
    # workspace.save(output_file_path,true)
  end

  def test_good_argument_values_missing_timestep_object
    # create an instance of the measure
    measure = TariffSelectionTimeAndDateDependant.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # remove timestep object, measure can add it now
    timestep = workspace.getObjectsByType('Timestep'.to_IddObjectType)[0]
    timestep.remove

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['summer_start_month'] = 5
    args_hash['summer_start_day'] = 1
    args_hash['summer_end_month'] = 9
    args_hash['summer_end_day'] = 1
    args_hash['peak_start_hour'] = 12
    args_hash['peak_end_hour'] = 18

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # save the workspace to output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_output.idf')
    # workspace.save(output_file_path,true)
  end

  def test_good_argument_values_wrap_around_time_and_day
    # create an instance of the measure
    measure = TariffSelectionTimeAndDateDependant.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['summer_start_month'] = 9
    args_hash['summer_start_day'] = 1
    args_hash['summer_end_month'] = 5
    args_hash['summer_end_day'] = 1
    args_hash['peak_start_hour'] = 22
    args_hash['peak_end_hour'] = 2

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # save the workspace to output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_output.idf')
    # workspace.save(output_file_path,true)
  end

  def test_good_argument_values_partial_hours
    # create an instance of the measure
    measure = TariffSelectionTimeAndDateDependant.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['summer_start_month'] = 5
    args_hash['summer_start_day'] = 1
    args_hash['summer_end_month'] = 9
    args_hash['summer_end_day'] = 1
    args_hash['peak_start_hour'] = 12.25
    args_hash['peak_end_hour'] = 18.5

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # save the workspace to output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_output.idf')
    workspace.save(output_file_path, true)
  end
end
