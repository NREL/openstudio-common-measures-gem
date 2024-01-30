# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class AddEMSEmissionsReporting_Test < MiniTest::Test

  def test_num_of_args_and_arg_names
    # create an instance of the measure
    measure = AddEMSEmissionsReporting.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    args = measure.arguments(model)
    assert_equal(6, args.size)
    assert_equal('future_subregion', args[0].name)
    assert_equal('hourly_historical_subregion', args[1].name)
    assert_equal('annual_historical_subregion', args[2].name)
    assert_equal('future_year', args[3].name)
    assert_equal('hourly_historical_year', args[4].name)
    assert_equal('annual_historical_year', args[5].name)
  end

  def test_good_arg_vals
    # create an instance of the measure
    measure = AddEMSEmissionsReporting.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    # runner = OpenStudio::Measure::OSRunner.new(osw)
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    trans = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/example_model.osm")
    model = trans.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    args = measure.arguments(model)
    arg_map = OpenStudio::Measure.convertOSArgumentVectorToMap(args)

    # create hash of argument values
    args_hash = {}

    # populate argument with specified hash value if specified
    args.each do |arg|
      tmp_arg = arg.clone
      if args_hash.key?(arg.name)
        assert(tmp_arg.setValue(args_hash[arg.name]))
      end
      arg_map[arg.name] = tmp_arg
    end

    # run the measure
    measure.run(model, runner, arg_map)
    result = runner.result

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert(result.value.valueName == 'Success')

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/test_output.osm")
    model.save(output_file_path, true)
  end

end
