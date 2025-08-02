# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here
require 'minitest/autorun'
require 'openstudio'
require_relative '../measure'

class SimulationControlTest < Minitest::Test

  def setup
  
    # make an empty model
    @model = OpenStudio::Model::Model.new

    # create an instance of the measure
    @measure = SimulationControl.new

    # make a hash of argument name to argument index to get argument from name rather than index
    @arguments_name_index_hash = {}
    @measure.arguments(@model).each_with_index do |argument, i|
      @arguments_name_index_hash[argument.name.to_sym] = i
    end

    # create runner with empty OSW
    @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    return @model, @measure, @runner, @arguments_name_index_hash   
  
  end

  # def teardown
  # end

  def test_arguments

    # get arguments
    arguments = @measure.arguments(@model)

    # test size
    assert_equal(12, arguments.size)

  end

  def test_run
    
    # expected model
    exp_model = @model.clone(true).to_Model
    exp_simulation_control = exp_model.getSimulationControl

    # actual model
    act_model = @model.clone(true).to_Model
    arguments = @measure.arguments(act_model)
    arguments_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    
    # setDoZoneSizingCalculation
    arg_val = true
    exp_simulation_control.setDoZoneSizingCalculation(arg_val)
    arg_idx = @arguments_name_index_hash[:do_zone_sizing_calculation]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:do_zone_sizing_calculation.to_s] = argument

    # setDoSystemSizingCalculation
    arg_val = true
    exp_simulation_control.setDoSystemSizingCalculation(arg_val)
    arg_idx = @arguments_name_index_hash[:do_system_sizing_calculation]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:do_system_sizing_calculation.to_s] = argument

    # setDoPlantSizingCalculation
    arg_val = true
    exp_simulation_control.setDoPlantSizingCalculation(arg_val)
    arg_idx = @arguments_name_index_hash[:do_plant_sizing_calculation]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:do_plant_sizing_calculation.to_s] = argument

    # setRunSimulationforSizingPeriods
    arg_val = false
    exp_simulation_control.setRunSimulationforSizingPeriods(arg_val)
    arg_idx = @arguments_name_index_hash[:run_simulation_for_sizing_periods]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:run_simulation_for_sizing_periods.to_s] = argument

    # setRunSimulationforWeatherFileRunPeriods
    arg_val = false
    exp_simulation_control.setRunSimulationforWeatherFileRunPeriods(arg_val)
    arg_idx = @arguments_name_index_hash[:run_simulation_for_weather_file_run_periods]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:run_simulation_for_weather_file_run_periods.to_s] = argument

    # setDoHVACSizingSimulationforSizingPeriods
    arg_val = true
    exp_simulation_control.setDoHVACSizingSimulationforSizingPeriods(arg_val)
    arg_idx = @arguments_name_index_hash[:do_hvac_sizing_simulation_for_sizing_periods]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:do_hvac_sizing_simulation_for_sizing_periods.to_s] = argument

    # setMaximumNumberofHVACSizingSimulationPasses
    arg_val = 20
    exp_simulation_control.setMaximumNumberofHVACSizingSimulationPasses(arg_val)
    arg_idx = @arguments_name_index_hash[:maximum_number_of_hvac_sizing_simulation_passes]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:maximum_number_of_hvac_sizing_simulation_passes.to_s] = argument

    # setLoadsConvergenceToleranceValue
    arg_val = 0.02
    exp_simulation_control.setLoadsConvergenceToleranceValue(arg_val)
    arg_idx = @arguments_name_index_hash[:loads_convergence_tolerance_value]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:loads_convergence_tolerance_value.to_s] = argument

    # setTemperatureConvergenceToleranceValue
    arg_val = 0.2
    exp_simulation_control.setTemperatureConvergenceToleranceValue(arg_val)
    arg_idx = @arguments_name_index_hash[:temperature_convergence_tolerance_value]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:temperature_convergence_tolerance_value.to_s] = argument

    # setSolarDistribution
    arg_val = 'FullInteriorAndExterior'
    exp_simulation_control.setSolarDistribution(arg_val)
    arg_idx = @arguments_name_index_hash[:solar_distribution]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:solar_distribution.to_s] = argument

    # setMaximumNumberofWarmupDays
    arg_val = 250
    exp_simulation_control.setMaximumNumberofWarmupDays(arg_val)
    arg_idx = @arguments_name_index_hash[:maximum_number_of_warmup_days]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:maximum_number_of_warmup_days.to_s] = argument

    # setMinimumNumberofWarmupDays
    arg_val = 10
    exp_simulation_control.setMinimumNumberofWarmupDays(arg_val)
    arg_idx = @arguments_name_index_hash[:minimum_number_of_warmup_days]
    argument = arguments[arg_idx].clone
    argument.setValue(arg_val)
    arguments_map[:minimum_number_of_warmup_days.to_s] = argument

    # run measure
    @measure.run(act_model, @runner, arguments_map)

    # tests
    assert_equal(
      exp_model.getSimulationControl.doZoneSizingCalculation,
      act_model.getSimulationControl.doZoneSizingCalculation)
    assert_equal(
      exp_model.getSimulationControl.doSystemSizingCalculation,
      act_model.getSimulationControl.doSystemSizingCalculation)
    assert_equal(
      exp_model.getSimulationControl.doPlantSizingCalculation,
      act_model.getSimulationControl.doPlantSizingCalculation)
    assert_equal(
      exp_model.getSimulationControl.runSimulationforSizingPeriods,
      act_model.getSimulationControl.runSimulationforSizingPeriods)
    assert_equal(
      exp_model.getSimulationControl.runSimulationforWeatherFileRunPeriods,
      act_model.getSimulationControl.runSimulationforWeatherFileRunPeriods)
    assert_equal(
      exp_model.getSimulationControl.doHVACSizingSimulationforSizingPeriods,
      act_model.getSimulationControl.doHVACSizingSimulationforSizingPeriods)
    assert_equal(
      exp_model.getSimulationControl.maximumNumberofHVACSizingSimulationPasses,
      act_model.getSimulationControl.maximumNumberofHVACSizingSimulationPasses)
    assert_equal(
      exp_model.getSimulationControl.loadsConvergenceToleranceValue,
      act_model.getSimulationControl.loadsConvergenceToleranceValue) 
    assert_equal(
      exp_model.getSimulationControl.temperatureConvergenceToleranceValue,
      act_model.getSimulationControl.temperatureConvergenceToleranceValue) 
    assert_equal(
      exp_model.getSimulationControl.solarDistribution,
      act_model.getSimulationControl.solarDistribution)
    assert_equal(
      exp_model.getSimulationControl.maximumNumberofWarmupDays,
      act_model.getSimulationControl.maximumNumberofWarmupDays)
    assert_equal(
      exp_model.getSimulationControl.minimumNumberofWarmupDays,
      act_model.getSimulationControl.minimumNumberofWarmupDays)

  end

end
