# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
