# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class SetLifecycleCostParameters_Test < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_SetLifecycleCostParameters
    # create an instance of the measure
    measure = SetLifecycleCostParameters.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
    assert_equal('study_period', arguments[0].name)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    study_period = arguments[0].clone
    assert(study_period.setValue(-10))
    argument_map['study_period'] = study_period
    measure.run(model, runner, argument_map)
    result = runner.result
    assert(result.value.valueName == 'Fail')

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    study_period = arguments[0].clone
    assert(study_period.setValue(20))
    argument_map['study_period'] = study_period
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.empty?)
  end
end
