# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class PredictedMeanVote_Test < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_PredictedMeanVote
    # create an instance of the measure
    measure = PredictedMeanVote.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/PMV_Exercise6PlusNewSchedules.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(6, arguments.size)
    assert_equal('comfortWarnings', arguments[0].name)
    assert_equal('meanRadiantCalcType', arguments[1].name)
    assert_equal('workEfficiencySchedule', arguments[2].name)
    assert_equal('clothingSchedule', arguments[3].name)
    assert_equal('airVelocitySchedule', arguments[4].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    comfortWarnings = arguments[0].clone
    assert(comfortWarnings.setValue(false))
    argument_map['comfortWarnings'] = comfortWarnings

    meanRadiantCalcType = arguments[1].clone
    assert(meanRadiantCalcType.setValue('ZoneAveraged'))
    argument_map['meanRadiantCalcType'] = meanRadiantCalcType

    workEfficiencySchedule = arguments[2].clone
    assert(workEfficiencySchedule.setValue('Work EfficiencySchedule 1'))
    argument_map['workEfficiencySchedule'] = workEfficiencySchedule

    clothingSchedule = arguments[3].clone
    assert(clothingSchedule.setValue('Clothing Insulation Schedule 1'))
    argument_map['clothingSchedule'] = clothingSchedule

    airVelocitySchedule = arguments[4].clone
    assert(airVelocitySchedule.setValue('Air Velocity Schedule'))
    argument_map['airVelocitySchedule'] = airVelocitySchedule

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 9)
  end
end
