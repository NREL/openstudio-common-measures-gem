# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class AddOutputDiagnostics_Test < Minitest::Test
  def test_AddOutputDiagnostics
    # create an instance of the measure
    measure = AddOutputDiagnostics.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # forward translate OpenStudio Model to EnergyPlus Workspace
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    assert_equal(1, arguments.size)
    assert_equal('outputDiagnostic', arguments[0].name)

    # set argument values to good values and run the measure on the workspace
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    outputDiagnostic = arguments[0].clone
    assert(outputDiagnostic.setValue('DisplayExtraWarnings'))
    argument_map['outputDiagnostic'] = outputDiagnostic

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.info.size == 1)

    # run again
    measure.run(workspace, runner, argument_map)
    result = runner.result
    assert(result.value.value == -1) # not applicable
  end
end
