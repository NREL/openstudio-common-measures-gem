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

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

# start the measure
class RunPeriodMultiple < OpenStudio::Measure::EnergyPlusMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'Set Multiple Run Period Object'
  end

  # human readable description
  def description
    return 'Set Multiple Run Period Object'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Set Multiple Run Period Object'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    # RunPeriodName
    runPeriodName = OpenStudio::Ruleset::OSArgument.makeStringArgument('runPeriodName', false)
    runPeriodName.setDisplayName('Run Period Name')
    runPeriodName.setDefaultValue('August')
    args << runPeriodName

    # BeginMonth
    beginMonth = OpenStudio::Ruleset::OSArgument.makeIntegerArgument('beginMonth', false)
    beginMonth.setDisplayName('Begin Month (integer)')
    beginMonth.setDefaultValue(8)
    args << beginMonth

    # BeginDay
    beginDay = OpenStudio::Ruleset::OSArgument.makeIntegerArgument('beginDay', false)
    beginDay.setDisplayName('Begin Day (integer)')
    beginDay.setDefaultValue(7)
    args << beginDay

    # EndMonth
    endMonth = OpenStudio::Ruleset::OSArgument.makeIntegerArgument('endMonth', false)
    endMonth.setDisplayName('End Month (integer)')
    endMonth.setDefaultValue(8)
    args << endMonth

    # EndDay
    endDay = OpenStudio::Ruleset::OSArgument.makeIntegerArgument('endDay', false)
    endDay.setDisplayName('End Day (integer)')
    endDay.setDefaultValue(8)
    args << endDay

    return args
  end # end the arguments method

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    runPeriodName = runner.getStringArgumentValue('runPeriodName', user_arguments)
    beginMonth = runner.getIntegerArgumentValue('beginMonth', user_arguments)
    endMonth = runner.getIntegerArgumentValue('endMonth', user_arguments)
    beginDay = runner.getIntegerArgumentValue('beginDay', user_arguments)
    endDay = runner.getIntegerArgumentValue('endDay', user_arguments)

    runPeriod = workspace.getObjectsByType('RunPeriod'.to_IddObjectType)

    runner.registerInitialCondition("The building has #{runPeriod.size} Run Period objects.")

    new_object_string = "
    RunPeriod,
      #{runPeriodName},  !- Name
      #{beginMonth},  !- Begin Month
      #{beginDay},  !- Begin Day of Month
      #{endMonth},  !- End Month
      #{endDay},  !- End Day of Month
      UseWeatherFile,  !- Day of Week for Start Day
      No,  !- Use Weather File Holidays and Special Days
      No,  !- Use Weather File Daylight Saving Period
      No,  !- Apply Weekend Holiday Rule
      Yes,  !- Use Weather File Rain Indicators
      Yes,  !- Use Weather File Snow Indicators
      1;    !- Number of Times Runperiod to be Repeated
    "

    idfObject = OpenStudio::IdfObject.load(new_object_string)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    new_object = wsObject.get

    runPeriod = workspace.getObjectsByType('RunPeriod'.to_IddObjectType)
    runner.registerFinalCondition("The building now has #{runPeriod.size} Run Period objects.")

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
RunPeriodMultiple.new.registerWithApplication
