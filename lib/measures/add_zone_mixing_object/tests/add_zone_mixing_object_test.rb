# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class AddZoneMixingObject_Test < Minitest::Test
  # def setup
  # end

  # def teardown

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = AddZoneMixingObject.new

    # make an empty workspace
    workspace = OpenStudio::Workspace.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    assert_equal(4, arguments.size)
  end

  def test_bad_argument_values
    # create an instance of the measure
    measure = AddZoneMixingObject.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty workspace
    workspace = OpenStudio::Workspace.new

    # get arguments
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set argument values to bad value
    zone_name = arguments[0].clone
    assert(zone_name.setValue('BadName'))
    argument_map['zone_name'] = zone_name

    schedule_name = arguments[1].clone
    assert(schedule_name.setValue('BadName'))
    argument_map['schedule_name'] = schedule_name

    design_level = arguments[2].clone
    assert(design_level.setValue(-5.0))
    argument_map['design_level'] = design_level

    source_zone_name = arguments[3].clone
    assert(source_zone_name.setValue('BadName'))
    argument_map['source_zone_name'] = source_zone_name

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    assert_equal('Fail', result.value.valueName)
  end

  def test_good_argument_values
    # create an instance of the measure
    measure = AddZoneMixingObject.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/ZoneMixingTestModel.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set argument values to good values
    zone_name = arguments[0].clone
    assert(zone_name.setValue('Thermal Zone 2'))
    argument_map['zone_name'] = zone_name

    schedule_name = arguments[1].clone
    assert(schedule_name.setValue('Always On Discrete'))
    argument_map['schedule_name'] = schedule_name

    design_level = arguments[2].clone
    assert(design_level.setValue(200.0))
    argument_map['design_level'] = design_level

    source_zone_name = arguments[3].clone
    assert(source_zone_name.setValue('Thermal Zone 9'))
    argument_map['source_zone_name'] = source_zone_name

    # run the measure
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # save the model in an output directory
    # save the model
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_output.idf')
    workspace.save(output_file_path, true)
  end
end
