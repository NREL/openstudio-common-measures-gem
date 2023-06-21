# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class GetSiteFromBuildingComponentLibraryTest < MiniTest::Unit::TestCase
  # method to apply arguments, run measure, and assert results (only populate args hash with non-default argument values)
  def apply_measure_to_model(test_name, args, model_name = nil, result_value = 'Success', warnings_count = 0, info_count = nil)
    # create an instance of the measure
    measure = GetSiteFromBuildingComponentLibrary.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    if model_name.nil?
      # make an empty model
      model = OpenStudio::Model::Model.new
    else
      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      path = OpenStudio::Path.new(File.dirname(__FILE__) + '/' + model_name)
      model = translator.loadModel(path)
      assert(!model.empty?)
      model = model.get
    end

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args.key?(arg.name)
        assert(temp_arg_var.setValue(args[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    puts "measure results for #{test_name}"
    show_output(result)

    # assert that it ran correctly
    if result_value.nil? then result_value = 'Success' end
    assert_equal(result_value, result.value.valueName)

    # check count of warning and info messages
    unless info_count.nil? then assert(result.info.size == info_count) end
    unless warnings_count.nil? then assert(result.warnings.size == warnings_count) end

    # if 'Fail' passed in make sure at least one error message (while not typical there may be more than one message)
    if result_value == 'Fail' then assert(result.errors.size >= 1) end

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/output/#{test_name}_test_output.osm")
    model.save(output_file_path, true)

    # special code just for get_site_from_bcl measure to look for known bad results when search results in first alphabetical site objects
    search_errors = []
    runner.result.info.each do |info|
      if info.logMessage.include?('Aberdeen Regional Arpt_SD')
        search_errors << info
      end
    end
    assert(search_errors.empty?)
  end

  def test_default_arguments
    skip 'do not want to test for now measures that get content from BCL'
    args = {}

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_memphis
    skip 'do not want to test for now measures that get content from BCL'

    args = {}
    args['zipcode'] = 38103

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_stl_int_airport
    skip 'do not want to test for now measures that get content from BCL'

    args = {}
    args['zipcode'] = 63145

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_lax
    skip 'do not want to test for now measures that get content from BCL'

    args = {}
    args['zipcode'] = 90045

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_zero_first
    skip 'do not want to test for now measures that get content from BCL'

    args = {}
    args['zipcode'] = '02908'.to_i

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm')
  end

  def test_too_big
    skip 'do not want to test for now measures that get content from BCL'

    args = {}
    args['zipcode'] = 999999

    apply_measure_to_model(__method__.to_s.gsub('test_', ''), args, 'example_model.osm', 'Fail')
  end
end
