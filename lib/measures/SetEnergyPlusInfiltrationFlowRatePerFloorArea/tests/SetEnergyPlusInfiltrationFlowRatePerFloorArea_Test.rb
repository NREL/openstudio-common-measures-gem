# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class SetEnergyPlusInfiltrationFlowRatePerFloorArea_Test < Minitest::Test
  def test_SetEnergyPlusInfiltrationFlowRatePerFloorArea
    # create an instance of the measure
    measure = SetEnergyPlusInfiltrationFlowRatePerFloorArea.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/Test.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)

    # set argument values to good values and run the measure on the workspace
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    flowPerZoneFloorArea = arguments[0].clone
    assert(flowPerZoneFloorArea.setValue('0.9999'))
    argument_map['flowPerZoneFloorArea'] = flowPerZoneFloorArea
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 6)
  end
end
