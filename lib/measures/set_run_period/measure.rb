# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2022, Alliance for Sustainable Energy, LLC.
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
