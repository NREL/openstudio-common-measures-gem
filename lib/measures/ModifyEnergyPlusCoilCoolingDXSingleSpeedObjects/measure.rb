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
class ModifyEnergyPlusCoilCoolingDXSingleSpeedObjects < OpenStudio::Measure::EnergyPlusMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'ModifyEnergyPlusCoilCoolingDXSingleSpeedObjects'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument
    ratedTotalCoolingCapacity = OpenStudio::Measure::OSArgument.makeDoubleArgument('ratedTotalCoolingCapacity', true)
    ratedTotalCoolingCapacity.setDisplayName('Rated Total Cooling Capacity (W).')
    # ratedTotalCoolingCapacity.setDefaultValue(10.76)
    args << ratedTotalCoolingCapacity

    # make an argument
    ratedCOP = OpenStudio::Measure::OSArgument.makeDoubleArgument('ratedCOP', true)
    ratedCOP.setDisplayName('Rated COP (W/W).')
    # ratedCOP.setDefaultValue(10.76)
    args << ratedCOP

    # make an argument
    ratedAirFlowRate = OpenStudio::Measure::OSArgument.makeDoubleArgument('ratedAirFlowRate', true)
    ratedAirFlowRate.setDisplayName('Rated Air Flow Rate (m^3/s).')
    # ratedAirFlowRate.setDefaultValue(10.76)
    args << ratedAirFlowRate

    # make an argument
    condensateRemovalStart = OpenStudio::Measure::OSArgument.makeDoubleArgument('condensateRemovalStart', true)
    condensateRemovalStart.setDisplayName('Nominal Time for Condensate Removal to Begin (s).')
    # condensateRemovalStart.setDefaultValue(10.76)
    args << condensateRemovalStart

    # make an argument
    evapLatentRatio = OpenStudio::Measure::OSArgument.makeDoubleArgument('evapLatentRatio', true)
    evapLatentRatio.setDisplayName('Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity.')
    # evapLatentRatio.setDefaultValue(10.76)
    args << evapLatentRatio

    # make an argument
    latentCapTimeConstant = OpenStudio::Measure::OSArgument.makeDoubleArgument('latentCapTimeConstant', true)
    latentCapTimeConstant.setDisplayName('Latent Capacity Time Constant (s).')
    # latentCapTimeConstant.setDefaultValue(10.76)
    args << latentCapTimeConstant

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
    ratedTotalCoolingCapacity = runner.getDoubleArgumentValue('ratedTotalCoolingCapacity', user_arguments)
    ratedCOP = runner.getDoubleArgumentValue('ratedCOP', user_arguments)
    ratedAirFlowRate = runner.getDoubleArgumentValue('ratedAirFlowRate', user_arguments)
    condensateRemovalStart = runner.getDoubleArgumentValue('condensateRemovalStart', user_arguments)
    evapLatentRatio = runner.getDoubleArgumentValue('evapLatentRatio', user_arguments)
    latentCapTimeConstant = runner.getDoubleArgumentValue('latentCapTimeConstant', user_arguments)

    # check the ratedTotalCoolingCapacity for reasonableness
    if ratedTotalCoolingCapacity < 0
      runner.registerError('Please enter a non-negative value for Rated Total Cooling Capacity.')
      return false
    end

    # check the ratedCOP for reasonableness
    if ratedCOP < 0
      runner.registerError('Please enter a non-negative value for Rated COP.')
      return false
    end

    # check the ratedAirFlowRate for reasonableness
    if ratedAirFlowRate < 0
      runner.registerError('Please enter a non-negative value for Rated Air Flow Rate.')
      return false
    end

    # check the condensateRemovalStart for reasonableness
    if condensateRemovalStart < 0
      runner.registerError('Please enter a non-negative value for Nominal Time for Condensate Removal to Begin.')
      return false
    end

    # check the evapLatentRatio for reasonableness
    if evapLatentRatio < 0
      runner.registerError('Please enter a non-negative value Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity.')
      return false
    end

    # check the latentCapTimeConstant for reasonableness
    if latentCapTimeConstant < 0
      runner.registerError('Please enter a non-negative value for Latent Capacity Time Constant.')
      return false
    end

    # get all coilCoolingSingleSpeedDxObjects in model
    coilCoolingSingleSpeedDxObjects = workspace.getObjectsByType('Coil:Cooling:DX:SingleSpeed'.to_IddObjectType)

    if coilCoolingSingleSpeedDxObjects.empty?
      runner.registerAsNotApplicable('The model does not contain any coilCoolingSingleSpeedDxObjects. The model will not be altered.')
      return true
    end

    coilCoolingSingleSpeedDxObjects.each do |coilCoolingSingleSpeedDxObject|
      coilCoolingSingleSpeedDxObject_name =  coilCoolingSingleSpeedDxObject.getString(0) # Name
      coilCoolingSingleSpeedDxObject_starting_ratedTotalCoolingCapacity = coilCoolingSingleSpeedDxObject.getString(2) # Rated Total Cooling Capacity
      coilCoolingSingleSpeedDxObject_starting_ratedCOP = coilCoolingSingleSpeedDxObject.getString(4) # Rated COP
      coilCoolingSingleSpeedDxObject_starting_ratedAirFlowRate = coilCoolingSingleSpeedDxObject.getString(5) # Rated Air Flow Rate
      coilCoolingSingleSpeedDxObject_starting_condensateRemovalStart = coilCoolingSingleSpeedDxObject.getString(14) # Nominal Time for Condensate Removal to Begin
      coilCoolingSingleSpeedDxObject_starting_evapLatentRatio = coilCoolingSingleSpeedDxObject.getString(15) # Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity
      coilCoolingSingleSpeedDxObject_starting_latentCapTimeConstant = coilCoolingSingleSpeedDxObject.getString(17) # Latent Capacity Time Constant
      coilCoolingSingleSpeedDxObject.setString(2, ratedTotalCoolingCapacity.to_s) # Rated Total Cooling Capacity
      coilCoolingSingleSpeedDxObject.setString(4, ratedCOP.to_s) # Rated COP
      coilCoolingSingleSpeedDxObject.setString(5, ratedAirFlowRate.to_s) # Rated Air Flow Rate
      coilCoolingSingleSpeedDxObject.setString(14, condensateRemovalStart.to_s) # Nominal Time for Condensate Removal to Begin
      coilCoolingSingleSpeedDxObject.setString(15, evapLatentRatio.to_s) # Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity
      coilCoolingSingleSpeedDxObject.setString(17, latentCapTimeConstant.to_s) # Latent Capacity Time Constant

      # info message on change
      runner.registerInfo("Changing Rated Total Cooling Capacity of #{coilCoolingSingleSpeedDxObject_name} from #{coilCoolingSingleSpeedDxObject_starting_ratedTotalCoolingCapacity}(Pa) to #{coilCoolingSingleSpeedDxObject.getString(2)}(Pa).")
      runner.registerInfo("Changing Rated COP of #{coilCoolingSingleSpeedDxObject_name} from #{coilCoolingSingleSpeedDxObject_starting_ratedCOP}(Pa) to #{coilCoolingSingleSpeedDxObject.getString(4)}(Pa).")
      runner.registerInfo("Changing Rated Air Flow Rate of #{coilCoolingSingleSpeedDxObject_name} from #{coilCoolingSingleSpeedDxObject_starting_ratedAirFlowRate}(Pa) to #{coilCoolingSingleSpeedDxObject.getString(5)}(Pa).")
      runner.registerInfo("Changing Nominal Time for Condensate Removal to Begin of #{coilCoolingSingleSpeedDxObject_name} from #{coilCoolingSingleSpeedDxObject_starting_condensateRemovalStart}(Pa) to #{coilCoolingSingleSpeedDxObject.getString(14)}(Pa).")
      runner.registerInfo("Changing Ratio of Initial Moisture Evaporation Rate and Steady State Latent Capacity of #{coilCoolingSingleSpeedDxObject_name} from #{coilCoolingSingleSpeedDxObject_starting_evapLatentRatio}(Pa) to #{coilCoolingSingleSpeedDxObject.getString(15)}(Pa).")
      runner.registerInfo("Changing Latent Capacity Time Constant of #{coilCoolingSingleSpeedDxObject_name} from #{coilCoolingSingleSpeedDxObject_starting_latentCapTimeConstant}(Pa) to #{coilCoolingSingleSpeedDxObject.getString(17)}(Pa).")
    end

    # TODO: - add warning if a thermal zone has more than one coilCoolingSingleSpeedDxObjects object, as that may not result in the desired impact.

    # TODO: - may also want to warn or have info message for zones that dont have any coilCoolingSingleSpeedDxObjects

    # unique initial conditions based on
    # removed listing ranges for variable values since we are editing multiple fields vs. a single field.
    runner.registerInitialCondition("The building has #{coilCoolingSingleSpeedDxObjects.size} coilCoolingSingleSpeedDxObject objects.")

    # reporting final condition of model
    runner.registerFinalCondition("The building finished with #{coilCoolingSingleSpeedDxObjects.size} coilCoolingSingleSpeedDxObject objects.")

    return true
  end
end

# this allows the measure to be use by the application
ModifyEnergyPlusCoilCoolingDXSingleSpeedObjects.new.registerWithApplication
