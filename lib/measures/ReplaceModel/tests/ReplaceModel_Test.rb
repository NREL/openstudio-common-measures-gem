# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'
require 'openstudio/ruleset/ShowRunnerOutput'

class ReplaceModel_Test < MiniTest::Unit::TestCase
  
  def test_ReplaceModel
    # get the example model
    model = OpenStudio::Model::exampleModel
    
    # create an instance of the measure
    measure = ReplaceModel.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    external_model_name = arguments[0].clone
    assert(external_model_name.setValue("EnvelopeAndLoadTestModel_01.osm"))
    argument_map["external_model_name"] = external_model_name
    
    # run the measure and test that it works
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    assert(result.value.valueName == "Success")
    assert(result.errors.empty?)
    assert(result.warnings.empty?)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test_output.osm")
    model.save(output_file_path,true)

  end

  def test_ReplaceModel_bad
    # get the example model
    model = OpenStudio::Model::exampleModel

    # create an instance of the measure
    measure = ReplaceModel.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osw")
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure::OSArgumentMap.new

    external_model_name = arguments[0].clone
    assert(external_model_name.setValue("BadName.osm"))
    argument_map["external_model_name"] = external_model_name

    # run the measure and test that it works
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    assert(result.value.valueName == "Fail")
    #assert(result.errors.empty?)
    #assert(result.warnings.empty?)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/test_output.osm")
    model.save(output_file_path,true)

  end

end


