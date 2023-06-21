# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class SetRunPeriod < OpenStudio::Ruleset::ModelUserScript
  # human readable name
  def name
    return 'SetRunPeriod'
  end

  # human readable description
  def description
    return 'Sets the run period and timestep for simulation'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    timesteps_per_hour = OpenStudio::Ruleset::OSArgument.makeIntegerArgument('timesteps_per_hour', true)
    timesteps_per_hour.setDisplayName('Timesteps per hour')
    timesteps_per_hour.setDescription('Number of simulation timesteps per hour')
    args << timesteps_per_hour

    begin_date = OpenStudio::Ruleset::OSArgument.makeStringArgument('begin_date', true)
    begin_date.setDisplayName('Begin date')
    begin_date.setDescription('Simulation start date, YYYY-MM-DD format')
    args << begin_date

    end_date = OpenStudio::Ruleset::OSArgument.makeStringArgument('end_date', true)
    end_date.setDisplayName('End date')
    end_date.setDescription('Simulation end date, YYYY-MM-DD format')
    args << end_date

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
    timesteps_per_hour = runner.getIntegerArgumentValue('timesteps_per_hour', user_arguments)
    begin_date = runner.getStringArgumentValue('begin_date', user_arguments)
    end_date = runner.getStringArgumentValue('end_date', user_arguments)

    # check for reasonableness
    if timesteps_per_hour < 1
      runner.registerError('Timesteps per hour must be greater than or equal to 1')
      return false
    end

    model.getTimestep.setNumberOfTimestepsPerHour(timesteps_per_hour)

    begin_year = nil
    begin_month = nil
    begin_day = nil
    if md = /(\d\d\d\d)-(\d\d)-(\d\d)/.match(begin_date)
      begin_year = md[1].to_i
      begin_month = md[2].to_i
      begin_day = md[3].to_i
    else
      runner.registerError('Begin date must be in YYYY-MM-DD format')
      return false
    end

    end_year = nil
    end_month = nil
    end_day = nil
    if md = /(\d\d\d\d)-(\d\d)-(\d\d)/.match(end_date)
      end_year = md[1].to_i
      end_month = md[2].to_i
      end_day = md[3].to_i
    else
      runner.registerError('End date must be in YYYY-MM-DD format')
      return false
    end

    d1 = OpenStudio::Date.new(OpenStudio.monthOfYear(begin_month), begin_day, begin_year)
    d2 = OpenStudio::Date.new(OpenStudio.monthOfYear(end_month), end_day, end_year)

    if d2 < d1
      runner.registerError('Begin date cannot be after end date')
      return false
    end

    if (d2 - d1).totalDays > 366
      runner.registerError('Maximum simulation period is 366 days')
      return false
    end

    model.getYearDescription.setCalendarYear(begin_year)
    model.getRunPeriod.setBeginMonth(begin_month)
    model.getRunPeriod.setBeginDayOfMonth(begin_day)
    model.getRunPeriod.setEndMonth(end_month)
    model.getRunPeriod.setEndDayOfMonth(end_day)

    return true
  end
end

# register the measure to be used by the application
SetRunPeriod.new.registerWithApplication
