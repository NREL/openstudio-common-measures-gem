

# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
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
class SetEnergyPlusMinimumOutdoorAirFlowRate < OpenStudio::Measure::EnergyPlusMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'SetEnergyPlusMinimumOutdoorAirFlowRate'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument
    minOutdoorAirFlow = OpenStudio::Measure::OSArgument.makeDoubleArgument('minOutdoorAirFlow', true)
    minOutdoorAirFlow.setDisplayName('Minimum Outdoor Air Flow Rate (m^3/s).')
    # minOutdoorAirFlow.setDefaultValue(10.76)
    args << minOutdoorAirFlow

    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    minOutdoorAirFlow = runner.getDoubleArgumentValue('minOutdoorAirFlow', user_arguments)

    # check the minOutdoorAirFlow for reasonableness
    if minOutdoorAirFlow < 0
      runner.registerError('Please enter a non-negative value for Minimum Outdoor Air Flow Rate.')
      return false
    end

    # get all outdoorAirObjects in model
    outdoorAirObjects = workspace.getObjectsByType('Controller:OutdoorAir'.to_IddObjectType)

    if outdoorAirObjects.empty?
      runner.registerAsNotApplicable('The model does not contain any outdoorAirObjects. The model will not be altered.')
      return true
    end

    starting_minOutdoorAirFlow_values = []
    final_minOutdoorAirFlow_values = []

    outdoorAirObjects.each do |outdoorAirObject|
      outdoorAirObject_name =  outdoorAirObject.getString(0) # Name
      outdoorAirObject_starting_minOutdoorAirFlow = outdoorAirObject.getString(5) # Minimum Outdoor Air Flow Rate
      outdoorAirObject.setString(5, minOutdoorAirFlow.to_s) # Minimum Outdoor Air Flow Rate

      # populate reporting arrays
      runner.registerInfo("Changing minimum outdoor air flow rate of #{outdoorAirObject_name} from #{outdoorAirObject_starting_minOutdoorAirFlow}(m^3/s) to #{outdoorAirObject.getString(5)}(m^3/s).")
      starting_minOutdoorAirFlow_values << outdoorAirObject_starting_minOutdoorAirFlow.get.to_f
      final_minOutdoorAirFlow_values << outdoorAirObject.getString(5).get.to_f
    end

    # TODO: - add warning if a thermal zone has more than one outdoorAirObjects object, as that may not result in the desired impact.

    # TODO: - may also want to warn or have info message for zones that dont have any outdoorAirObjects

    # unique initial conditions based on
    runner.registerInitialCondition("The building has #{outdoorAirObjects.size} outdoorAirObject objects, and started with minimum outdoor air flow rate values ranging from #{starting_minOutdoorAirFlow_values.min} to #{starting_minOutdoorAirFlow_values.max}.")

    # reporting final condition of model
    runner.registerFinalCondition("The building finished with minimum outdoor air flow rate values ranging from #{final_minOutdoorAirFlow_values.min} to #{final_minOutdoorAirFlow_values.max}.")

    return true
  end
end

# this allows the measure to be use by the application
SetEnergyPlusMinimumOutdoorAirFlowRate.new.registerWithApplication
