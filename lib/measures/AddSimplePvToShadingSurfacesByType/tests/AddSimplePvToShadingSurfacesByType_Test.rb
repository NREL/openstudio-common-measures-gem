# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class AddSimplePvToShadingSurfacesByType_Test < Minitest::Test
  def test_AddSimplePvToShadingSurfacesByType_a
    # create an instance of the measure
    measure = AddSimplePvToShadingSurfacesByType.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    assert_equal(7, arguments.size)
      end

  def test_AddSimplePvToShadingSurfacesByType_b
    # create an instance of the measure
    measure = AddSimplePvToShadingSurfacesByType.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/PV_test_model.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    shading_type = arguments[count += 1].clone
    assert(shading_type.setValue('Building Shading'))
    argument_map['shading_type'] = shading_type

    fraction_surfacearea_with_pv = arguments[count += 1].clone
    assert(fraction_surfacearea_with_pv.setValue('0.5'))
    argument_map['fraction_surfacearea_with_pv'] = fraction_surfacearea_with_pv

    value_for_cell_efficiency = arguments[count += 1].clone
    assert(value_for_cell_efficiency.setValue('0.12'))
    argument_map['value_for_cell_efficiency'] = value_for_cell_efficiency

    material_cost = arguments[count += 1].clone
    assert(material_cost.setValue(20000.0))
    argument_map['material_cost'] = material_cost

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map['expected_life'] = expected_life

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(500.0))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(5))
    argument_map['om_frequency'] = om_frequency

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
      end
end
