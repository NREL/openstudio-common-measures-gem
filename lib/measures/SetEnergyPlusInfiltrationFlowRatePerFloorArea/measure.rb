

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
class SetEnergyPlusInfiltrationFlowRatePerFloorArea < OpenStudio::Measure::EnergyPlusMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'SetEnergyPlusInfiltrationFlowRatePerFloorArea'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument
    flowPerZoneFloorArea = OpenStudio::Measure::OSArgument.makeDoubleArgument('flowPerZoneFloorArea', true)
    flowPerZoneFloorArea.setDisplayName('Flow per Zone Floor Area (m^3/s-m^2).')
    # flowPerZoneFloorArea.setDefaultValue(10.76)
    args << flowPerZoneFloorArea

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
    flowPerZoneFloorArea = runner.getDoubleArgumentValue('flowPerZoneFloorArea', user_arguments)

    # check the flowPerZoneFloorArea for reasonableness
    if flowPerZoneFloorArea < 0
      runner.registerError('Please enter a non-negative value for Flow per Zone Floor Area.')
      return false
    end

    # get all infiltrationObjects in model
    infiltrationObjects = workspace.getObjectsByType('ZoneInfiltration:DesignFlowRate'.to_IddObjectType)

    if infiltrationObjects.empty?
      runner.registerAsNotApplicable('The model does not contain any infiltration objects. The model will not be altered.')
      return true
    end

    starting_flowPerZoneFloorArea_values = []
    non_flowPerZoneFloorArea_starting = []
    final_flowPerZoneFloorArea_values = []

    infiltrationObjects.each do |infiltrationObject|
      infiltrationObject_name =  infiltrationObject.getString(0) # Name
      infiltrationObject_starting_calc = infiltrationObject.getString(3) # Design Flow Rate Calculation Method
      infiltrationObject_starting_flowPerZoneFloorArea = infiltrationObject.getString(5) # Flow per Zone Floor Area
      infiltrationObject.setString(3, 'Flow/Area') # Design Flow Rate Calculation Method
      infiltrationObject.setString(5, flowPerZoneFloorArea.to_s) # Flow per Zone Floor Area

      # populate reporting arrays
      if infiltrationObject_starting_calc.to_s == 'Flow/Area'
        runner.registerInfo("Changing #{infiltrationObject_name} from flow per zone floor area of #{infiltrationObject_starting_flowPerZoneFloorArea}(m^3/s-m^2) to #{infiltrationObject.getString(5)}(W/m^2).")
        starting_flowPerZoneFloorArea_values << infiltrationObject_starting_flowPerZoneFloorArea.get.to_f
        final_flowPerZoneFloorArea_values << infiltrationObject.getString(5).get.to_f
      else
        runner.registerInfo("Setting flow per zone floor area of #{infiltrationObject_name} to #{infiltrationObject.getString(5)}(m^3/s-m^2) and changing design flow calculation rate method to Flow/Zone. Original design flow calculation method was #{infiltrationObject_starting_calc}.")
        non_flowPerZoneFloorArea_starting << infiltrationObject_name
        final_flowPerZoneFloorArea_values << infiltrationObject.getString(5).get.to_f
      end
    end

    # TODO: - add warning if a thermal zone has more than one infiltrationObjects object, as that may not result in the desired impact.

    # TODO: - may also want to warn or have info message for zones that dont have any infiltrationObjects

    # unique initial conditions based on
    if !starting_flowPerZoneFloorArea_values.empty? && non_flowPerZoneFloorArea_starting.empty?
      runner.registerInitialCondition("The building has #{infiltrationObjects.size} infiltrationObject objects, and started with flow per zone floor area values ranging from #{starting_flowPerZoneFloorArea_values.min} to #{starting_flowPerZoneFloorArea_values.max}.")
    elsif !starting_flowPerZoneFloorArea_values.empty? && !non_flowPerZoneFloorArea_starting.empty?
      runner.registerInitialCondition("The building has #{infiltrationObjects.size} infiltrationObject objects, and started with flow per zone floor area values ranging from #{starting_flowPerZoneFloorArea_values.min} to #{starting_flowPerZoneFloorArea_values.max}. #{non_flowPerZoneFloorArea_starting.size} infiltrationObject objects did not start as Flow/Area, and are not included in the flow per zone floor area range.")
    else
      runner.registerInitialCondition("The building has #{infiltrationObjects.size} infiltrationObject objects. None of the infiltrationObjects started as Flow/Area.")
    end

    # reporting final condition of model
    runner.registerFinalCondition("The building finished with flow per zone floor area values ranging from #{final_flowPerZoneFloorArea_values.min} to #{final_flowPerZoneFloorArea_values.max}.")

    return true
  end
end

# this allows the measure to be use by the application
SetEnergyPlusInfiltrationFlowRatePerFloorArea.new.registerWithApplication
