# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SimulationControl < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Simulation Control'
  end

  # human readable description
  def description
    return 'The measures sets simulation control, timestep and convergence parameters.'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    do_zone_sizing_calculation = OpenStudio::Measure::OSArgument.makeBoolArgument("do_zone_sizing_calculation", false)
    do_zone_sizing_calculation.setDisplayName("Do Zone Sizing Calculation?")
    do_zone_sizing_calculation.setDefaultValue(false)
    args << do_zone_sizing_calculation

    do_system_sizing_calculation = OpenStudio::Measure::OSArgument.makeBoolArgument("do_system_sizing_calculation", false)
    do_system_sizing_calculation.setDisplayName("Do System Sizing Calculation?")
    do_system_sizing_calculation.setDefaultValue(false)
    args << do_system_sizing_calculation

    do_plant_sizing_calculation = OpenStudio::Measure::OSArgument.makeBoolArgument("do_plant_sizing_calculation", false)
    do_plant_sizing_calculation.setDisplayName("Do Plant Sizing Calculation?")
    do_plant_sizing_calculation.setDefaultValue(false)
    args << do_plant_sizing_calculation

    run_simulation_for_sizing_periods = OpenStudio::Measure::OSArgument.makeBoolArgument("run_simulation_for_sizing_periods", false)
    run_simulation_for_sizing_periods.setDisplayName("Run Simulation for Sizing Periods?")
    run_simulation_for_sizing_periods.setDefaultValue(true)
    args << run_simulation_for_sizing_periods

    run_simulation_for_weather_file_run_periods = OpenStudio::Measure::OSArgument.makeBoolArgument("run_simulation_for_weather_file_run_periods", false)
    run_simulation_for_weather_file_run_periods.setDisplayName("Run Simulation for Weather File Run Periods?")
    run_simulation_for_weather_file_run_periods.setDefaultValue(true)
    args << run_simulation_for_weather_file_run_periods

    do_hvac_sizing_simulation_for_sizing_periods = OpenStudio::Measure::OSArgument.makeBoolArgument('do_hvac_sizing_simulation_for_sizing_periods', false)
    do_hvac_sizing_simulation_for_sizing_periods.setDisplayName('Do HVAC Sizing Simulation for Sizing Periods?')
    do_hvac_sizing_simulation_for_sizing_periods.setDefaultValue(false)
    args << do_hvac_sizing_simulation_for_sizing_periods

    maximum_number_of_hvac_sizing_simulation_passes = OpenStudio::Measure::OSArgument.makeIntegerArgument('maximum_number_of_hvac_sizing_simulation_passes', false)
    maximum_number_of_hvac_sizing_simulation_passes.setDisplayName('Maximum Number of HVAC Sizing Simulation Passes')
    maximum_number_of_hvac_sizing_simulation_passes.setDescription('only used if the previous field is set to Yes')
    args << maximum_number_of_hvac_sizing_simulation_passes

    # the following fields belong to the Building class in EnergyPlus
    loads_convergence_tolerance_value = OpenStudio::Measure::OSArgument.makeDoubleArgument("loads_convergence_tolerance_value", false)
    loads_convergence_tolerance_value.setDisplayName("Loads Convergence Tolerance Value")
    args << loads_convergence_tolerance_value

    temperature_convergence_tolerance_value = OpenStudio::Measure::OSArgument.makeDoubleArgument("temperature_convergence_tolerance_value", false)
    temperature_convergence_tolerance_value.setDisplayName("Temperature Convergence Tolerance Value")
    args << temperature_convergence_tolerance_value

    solar_distributions = OpenStudio::StringVector.new
    solar_distributions << "FullExterior"
    solar_distributions << "MinimalShadowing"
    solar_distributions << "FullInteriorAndExterior"
    solar_distributions << "FullExteriorWithReflections"
    solar_distributions << "FullInteriorAndExteriorWithReflections"
    solar_distribution = OpenStudio::Measure::OSArgument.makeChoiceArgument("solar_distribution", solar_distributions, false)
    solar_distribution.setDisplayName("Solar Distribution")
    args << solar_distribution

    maximum_number_of_warmup_days = OpenStudio::Measure::OSArgument.makeIntegerArgument("maximum_number_of_warmup_days", false)
    maximum_number_of_warmup_days.setDisplayName("Maximum Number of Warmup Days")
    args << maximum_number_of_warmup_days

    minimum_number_of_warmup_days = OpenStudio::Measure::OSArgument.makeIntegerArgument("minimum_number_of_warmup_days", false)
    minimum_number_of_warmup_days.setDisplayName("Minimum Number of Warmup Days")
    args << minimum_number_of_warmup_days

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # get object
    simulation_control = model.getSimulationControl

    # register initial condition
    runner.registerInitialCondition("#{simulation_control}")

    # get arguments
    do_zone_sizing_calculation = runner.getBoolArgumentValue("do_zone_sizing_calculation", user_arguments)
    do_system_sizing_calculation = runner.getBoolArgumentValue("do_system_sizing_calculation", user_arguments)
    do_plant_sizing_calculation = runner.getBoolArgumentValue("do_plant_sizing_calculation", user_arguments)
    run_simulation_for_sizing_periods = runner.getBoolArgumentValue("run_simulation_for_sizing_periods", user_arguments)
    run_simulation_for_weather_file_run_periods = runner.getBoolArgumentValue("run_simulation_for_weather_file_run_periods", user_arguments)
    do_hvac_sizing_simulation_for_sizing_periods = runner.getBoolArgumentValue('do_hvac_sizing_simulation_for_sizing_periods', user_arguments)
    if runner.getOptionalIntegerArgumentValue('maximum_number_of_hvac_sizing_simulation_passes', user_arguments).is_initialized
      maximum_number_of_hvac_sizing_simulation_passes = runner.getOptionalIntegerArgumentValue('maximum_number_of_hvac_sizing_simulation_passes', user_arguments)
    else
      maximum_number_of_hvac_sizing_simulation_passes = false
    end
    if runner.getOptionalDoubleArgumentValue("loads_convergence_tolerance_value", user_arguments).is_initialized
      loads_convergence_tolerance_value = runner.getOptionalDoubleArgumentValue("loads_convergence_tolerance_value", user_arguments)
    else
      loads_convergence_tolerance_value = false
    end
    if runner.getOptionalDoubleArgumentValue("temperature_convergence_tolerance_value", user_arguments).is_initialized
      temperature_convergence_tolerance_value = runner.getOptionalDoubleArgumentValue("temperature_convergence_tolerance_value", user_arguments)
    else
      temperature_convergence_tolerance_value = false
    end
    if runner.getOptionalStringArgumentValue("solar_distribution", user_arguments).is_initialized
      solar_distribution = runner.getOptionalStringArgumentValue("solar_distribution", user_arguments)
    else
      solar_distribution = false
    end
    if runner.getOptionalIntegerArgumentValue("maximum_number_of_warmup_days", user_arguments).is_initialized
      maximum_number_of_warmup_days = runner.getOptionalIntegerArgumentValue("maximum_number_of_warmup_days", user_arguments)
    else
      maximum_number_of_warmup_days = false
    end
    if runner.getOptionalIntegerArgumentValue("minimum_number_of_warmup_days", user_arguments).is_initialized
      minimum_number_of_warmup_days = runner.getOptionalIntegerArgumentValue("minimum_number_of_warmup_days", user_arguments)
    else
      minimum_number_of_warmup_days = false
    end

    # set object
    simulation_control.setDoZoneSizingCalculation(do_zone_sizing_calculation)
    simulation_control.setDoSystemSizingCalculation(do_system_sizing_calculation)
    simulation_control.setDoPlantSizingCalculation(do_plant_sizing_calculation)
    simulation_control.setRunSimulationforSizingPeriods(run_simulation_for_sizing_periods)
    simulation_control.setRunSimulationforWeatherFileRunPeriods(run_simulation_for_weather_file_run_periods)
    simulation_control.setDoHVACSizingSimulationforSizingPeriods(do_hvac_sizing_simulation_for_sizing_periods)
    simulation_control.setMaximumNumberofHVACSizingSimulationPasses(maximum_number_of_hvac_sizing_simulation_passes.get) if maximum_number_of_hvac_sizing_simulation_passes
    simulation_control.setLoadsConvergenceToleranceValue(loads_convergence_tolerance_value.get) if loads_convergence_tolerance_value
    simulation_control.setTemperatureConvergenceToleranceValue(temperature_convergence_tolerance_value.get) if temperature_convergence_tolerance_value
    simulation_control.setSolarDistribution(solar_distribution.get) if solar_distribution
    simulation_control.setMaximumNumberofWarmupDays(maximum_number_of_warmup_days.get) if maximum_number_of_warmup_days
    simulation_control.setMinimumNumberofWarmupDays(minimum_number_of_warmup_days.get) if minimum_number_of_warmup_days

    # register final condition
    runner.registerFinalCondition("#{simulation_control}")

    return true
  end

end

# register the measure to be used by the application
SimulationControl.new.registerWithApplication
