# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class OutputTableSummaryReports < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Output Table Summary Reports'
  end

  # human readable description
  def description
    return 'This Measure adds one of the predefined summary table outputs from EnergyPlus to the the Model, which can be helpful for requesting monthly or sizing reports.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'OpenStudio automatically adds the AllSummary report during translation to EnergyPlus. Choices include reports with the All* prefix and do not include individual predefined reports such as the "Annual Building Utility Performance Summary". Including the Component Load Summary reports (any with *AndSizingPeriod) will increase the simulation run time'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make choice argument for output summary value
    choices = OpenStudio::StringVector.new
    choices << 'AllSummary'
    choices << 'AllMonthly'
    choices << 'AllSummaryAndMonthly'
    choices << 'AllSummaryAndSizingPeriod'
    choices << 'AllSummaryMonthlyAndSizingPeriod'
    report = OpenStudio::Ruleset::OSArgument::makeChoiceArgument('report', choices, true)
    report.setDisplayName('Output Table Summary Report')
    report.setDescription('AllSummary is added automatically by OpenStudio.')
    report.setDefaultValue('AllSummaryAndSizingPeriod')
    args << report

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    report = runner.getStringArgumentValue('report', user_arguments)

    # get object, which will instantiate it if it doesn't exist
    otsr = model.getOutputTableSummaryReports

    # report initial condition
    runner.registerInitialCondition("Output Table Summary Reports = #{otsr.summaryReports}")

    # add report to object
    otsr.addSummaryReport(report)

    # report final condition
    runner.registerFinalCondition("Output Table Summary Reports = #{otsr.summaryReports}")

    return true
  end
end

# register the measure to be used by the application
OutputTableSummaryReports.new.registerWithApplication
