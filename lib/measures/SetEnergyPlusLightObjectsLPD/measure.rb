

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
class SetEnergyPlusLightObjectsLPD < OpenStudio::Measure::EnergyPlusMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'SetEnergyPlusLightObjectsLPD'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument LPD
    lpd = OpenStudio::Measure::OSArgument.makeDoubleArgument('lpd', true)
    lpd.setDisplayName('Lighting Power Density (W/m^2)')
    lpd.setDefaultValue(10.76)
    args << lpd

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
    lpd = runner.getDoubleArgumentValue('lpd', user_arguments)

    # check the lpd for reasonableness
    if (lpd < 0) || (lpd > 538)
      runner.registerError("A Lighting Power Density of #{lpd} W/m^2 is above the measure limit.")
      return false
    elsif lpd > 226
      runner.registerWarning("A Lighting Power Density of #{lpd} W/m^2 is abnormally high.")
    end

    # get all lights in model
    lights = workspace.getObjectsByType('Lights'.to_IddObjectType)

    if lights.empty?
      runner.registerAsNotApplicable('The model does not contain any lights. The model will not be altered.')
      return true
    end

    starting_lpd_values = []
    non_lpd_starting = []
    final_lpd_values = []

    lights.each do |light|
      light_name =  light.getString(0) # Name
      light_starting_calc = light.getString(3) # Design Level Calculation Method
      light_starting_lpd = light.getString(5) # Watts per Zone Floor Area
      light.setString(3, 'Watts/Area') # Design Level Calculation Method
      light.setString(5, lpd.to_s) # Watts per Zone Floor Area

      # populate reporting arrays
      if light_starting_calc.to_s == 'Watts/Area'
        runner.registerInfo("Changing LPD of #{light_name} from #{light_starting_lpd}(W/m^2) to #{light.getString(5)}(W/m^2).")
        starting_lpd_values << light_starting_lpd.get.to_f
        final_lpd_values << light.getString(5).get.to_f
      else
        runner.registerInfo("Setting LPD of #{light_name} to #{light.getString(5)}(W/m^2). Original design level calculation method was #{light_starting_calc}.")
        non_lpd_starting << light_name
        final_lpd_values << light.getString(5).get.to_f
      end
    end

    # TODO: - add warning if a thermal zone has more than one lights object, as that may not result in the desired impact.

    # TODO: - may also want to warn or have info message for zones that dont have any lights

    # unique initial conditions based on
    if !starting_lpd_values.empty? && non_lpd_starting.empty?
      runner.registerInitialCondition("The building has #{lights.size} light objects, and started with LPD values ranging from #{starting_lpd_values.min} to #{starting_lpd_values.max}.")
    elsif !starting_lpd_values.empty? && !non_lpd_starting.empty?
      runner.registerInitialCondition("The building has #{lights.size} light objects, and started with LPD values ranging from #{starting_lpd_values.min} to #{starting_lpd_values.max}. #{non_lpd_starting.size} light objects did not start as Watts/Area, and are not included in the LPD range.")
    else
      runner.registerInitialCondition("The building has #{lights.size} light objects. None of the lights started as Watts/Area.")
    end

    # reporting final condition of model
    runner.registerFinalCondition("The building finished with LPD values ranging from #{final_lpd_values.min} to #{final_lpd_values.max}.")

    return true
  end
end

# this allows the measure to be use by the application
SetEnergyPlusLightObjectsLPD.new.registerWithApplication
