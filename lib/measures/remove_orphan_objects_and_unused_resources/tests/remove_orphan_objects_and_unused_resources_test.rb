# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class RemoveOrphanObjectsAndUnusedResourcesTest < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = RemoveOrphanObjectsAndUnusedResources.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)
  end

  def test_good_argument_values
    # create an instance of the measure
    measure = RemoveOrphanObjectsAndUnusedResources.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/1125_infil_test_a.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set argument values to good values
    remove_unused_space_types = arguments[0].clone
    assert(remove_unused_space_types.setValue(true))
    argument_map['remove_unused_space_types'] = remove_unused_space_types

    remove_unused_load_defs = arguments[1].clone
    assert(remove_unused_load_defs.setValue(true))
    argument_map['remove_unused_load_defs'] = remove_unused_load_defs

    remove_unused_schedules = arguments[2].clone
    assert(remove_unused_schedules.setValue(true))
    argument_map['remove_unused_schedules'] = remove_unused_schedules

    remove_unused_curves = arguments[3].clone
    assert(remove_unused_curves.setValue(true))
    argument_map['remove_unused_curves'] = remove_unused_curves

    remove_unused_constructions = arguments[4].clone
    assert(remove_unused_constructions.setValue(true))
    argument_map['remove_unused_constructions'] = remove_unused_constructions

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal('Success', result.value.valueName)

    # save the model
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test.osm')
    model.save(output_file_path, true)
  end
end
