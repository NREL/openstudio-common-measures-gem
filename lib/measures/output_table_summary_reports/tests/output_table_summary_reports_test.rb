# insert your copyright here

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'

class OutputTableSummaryReportsTest < Minitest::Test

  def setup

    # create a model
    @model = OpenStudio::Model.exampleModel()

    # create an instance of the measure
    @measure = OutputTableSummaryReports.new

    # make a hash of argument name to argument index to get argument from name rather than index
    @arguments_name_index_hash = {}
    @measure.arguments(@model).each_with_index do |argument, i|
      @arguments_name_index_hash[argument.name.to_sym] = i
    end

    # create runner with empty OSW
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    return @model, @measure, @arguments_name_index_hash, @runner

  end

  def test_run

    # expected model
    exp_model = @model.clone(true).to_Model
    exp_object = exp_model.getOutputTableSummaryReports

    # actual model
    act_model = @model.clone(true).to_Model
    arguments = @measure.arguments(act_model)
    arguments_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # method addSummaryReport
    arg_val = 'AllSummaryAndSizingPeriod'
    exp_object.addSummaryReport(arg_val)
    arg_idx = @arguments_name_index_hash[:report]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:report.to_s] = argument

    # run measure
    @measure.run(act_model, @runner, arguments_map)

    # tests
    assert_includes(exp_model.getOutputTableSummaryReports.summaryReports, arg_val)

  end

end
