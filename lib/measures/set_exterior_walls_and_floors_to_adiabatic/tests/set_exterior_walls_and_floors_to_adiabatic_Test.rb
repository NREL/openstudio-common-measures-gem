# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class SetExteriorWallsAndFloorsToAdiabatic_Test < Minitest::Test
  def test_SetExteriorWallsAndFloorsToAdiabatic
    # create an instance of the measure
    measure = SetExteriorWallsAndFloorsToAdiabatic.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    ext_roofs = arguments[0].clone
    assert(ext_roofs.setValue(true))
    argument_map['ext_roofs'] = ext_roofs
    ground_floors = arguments[2].clone
    assert(ground_floors.setValue(false))
    argument_map['ground_floors'] = ground_floors
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.empty?)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/roof.osm')
    model.save(output_file_path, true)
  end

  def test_SetExteriorWallsAndFloorsToAdiabatic_ground
    # create an instance of the measure
    measure = SetExteriorWallsAndFloorsToAdiabatic.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    ext_roofs = arguments[0].clone
    assert(ext_roofs.setValue(false))
    argument_map['ext_roofs'] = ext_roofs
    ground_floors = arguments[2].clone
    assert(ground_floors.setValue(true))
    argument_map['ground_floors'] = ground_floors
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.empty?)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/floor.osm')
    model.save(output_file_path, true)
  end

  def test_SetExteriorWallsAndFloorsToAdiabatic_walls
    # create an instance of the measure
    measure = SetExteriorWallsAndFloorsToAdiabatic.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    ext_roofs = arguments[0].clone
    assert(ext_roofs.setValue(false))
    argument_map['ext_roofs'] = ext_roofs
    ground_floors = arguments[2].clone
    assert(ground_floors.setValue(false))
    argument_map['ground_floors'] = ground_floors
    south_walls = arguments[4].clone
    assert(south_walls.setValue(true))
    argument_map['south_walls'] = south_walls
    east_walls = arguments[5].clone
    assert(east_walls.setValue(true))
    argument_map['east_walls'] = east_walls
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.empty?)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/walls.osm')
    model.save(output_file_path, true)
  end

  def test_SetExteriorWallsAndFloorsToAdiabatic_list
    # create an instance of the measure
    measure = SetExteriorWallsAndFloorsToAdiabatic.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    ext_roofs = arguments[0].clone
    assert(ext_roofs.setValue(true))
    argument_map['ext_roofs'] = ext_roofs
    ground_floors = arguments[2].clone
    assert(ground_floors.setValue(false))
    argument_map['ground_floors'] = ground_floors
    inclusion_list = arguments[7].clone
    assert(inclusion_list.setValue('Surface 2|Surface 4|Surface 5'))
    argument_map['inclusion_list'] = inclusion_list
    exclusion_list = arguments[8].clone
    assert(exclusion_list.setValue('Surface 5|surface 6'))
    argument_map['exclusion_list'] = exclusion_list
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 1)
    assert(result.info.empty?)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/roof.osm')
    model.save(output_file_path, true)
  end
end
