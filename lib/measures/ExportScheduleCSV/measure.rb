# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# start the measure
class ExportScheduleCSV < OpenStudio::Measure::ReportingMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'ExportScheduleCSV'
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    interval_arg = OpenStudio::Measure::OSArgument.makeIntegerArgument('interval', false)
    interval_arg.setDisplayName('Time Interval (minutes)')
    interval_arg.setDefaultValue(60)
    args << interval_arg

    return args
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    interval_arg = user_arguments['interval']

    interval = interval_arg.defaultValueAsInteger
    if interval_arg.hasValue
      interval = interval_arg.valueAsInteger
    end

    # get the last model
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    header = []
    header << 'Time'
    schedules = []

    model.getScheduleDays.each do |schedule|
      header << schedule.name.get
      schedules << schedule
    end

    dt = OpenStudio::Time.new(0, 0, interval, 0)
    time = OpenStudio::Time.new(0, 0, 0, 0)
    stop = OpenStudio::Time.new(1, 0, 0, 0)
    values = []
    while time <= stop
      row = []
      row << time.to_s
      schedules.each do |schedule|
        row << schedule.getValue(time)
      end
      values << row

      time += dt
    end

    # if we want this report could write out a csv, html, or any other file here
    runner.registerInfo("Writing CSV report 'report.csv'")
    File.open('report.csv', 'w') do |file|
      file.puts header.join(',')
      values.each do |row|
        file.puts row.join(',')
      end
    end

    # reporting final condition
    runner.registerFinalCondition("Wrote CSV for #{schedules.size} day schedules.")

    return true
  end
end

# this allows the measure to be use by the application
ExportScheduleCSV.new.registerWithApplication
