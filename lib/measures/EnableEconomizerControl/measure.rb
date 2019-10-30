# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC.
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
class EnableEconomizerControl < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'Enable Economizer Control'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make choice argument economizer control type
    choices = OpenStudio::StringVector.new
    choices << 'FixedDryBulb'
    choices << 'NoEconomizer'
    choices << 'NoChange'
    economizer_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('economizer_type', choices, true)
    economizer_type.setDisplayName('Economizer Control Type')
    args << economizer_type

    # make an argument for econoMaxDryBulbTemp
    econoMaxDryBulbTemp = OpenStudio::Measure::OSArgument.makeDoubleArgument('econoMaxDryBulbTemp', true)
    econoMaxDryBulbTemp.setDisplayName('Economizer Maximum Limit Dry-Bulb Temperature (F).')
    econoMaxDryBulbTemp.setDefaultValue(69.0)
    args << econoMaxDryBulbTemp

    # make an argument for econoMinDryBulbTemp
    econoMinDryBulbTemp = OpenStudio::Measure::OSArgument.makeDoubleArgument('econoMinDryBulbTemp', true)
    econoMinDryBulbTemp.setDisplayName('Economizer Minimum Limit Dry-Bulb Temperature (F).')
    econoMinDryBulbTemp.setDefaultValue(-148.0)
    args << econoMinDryBulbTemp

    return args
  end

  # define what happens when the measure is cop
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    economizer_type = runner.getStringArgumentValue('economizer_type', user_arguments)
    econoMaxDryBulbTemp = runner.getDoubleArgumentValue('econoMaxDryBulbTemp', user_arguments)
    econoMinDryBulbTemp = runner.getDoubleArgumentValue('econoMinDryBulbTemp', user_arguments)

    # Note if economizer_type == NoChange
    # and register as N/A
    if economizer_type == 'NoChange'
      runner.registerAsNotApplicable('N/A - User requested No Change in economizer operation.')
      return true
    end

    # short def to make numbers pretty (converts 4125001.25641 to 4,125,001.26 or 4,125,001). The definition be called through this measure
    def neat_numbers(number, roundto = 2) # round to 0 or 2)
      if roundto == 2
        number = format '%.2f', number
      else
        number = number.round
      end
      # regex to add commas
      number.to_s.reverse.gsub(/([0-9]{3}(?=([0-9])))/, '\\1,').reverse
    end

    # info for initial condition
    air_loops_changed = []
    loops_with_outdoor_air = false

    # loop through air loops
    model.getAirLoopHVACs.each do |air_loop|
      # find AirLoopHVACOutdoorAirSystem on loop
      air_loop.supplyComponents.each do |supply_component|
        hVACComponent = supply_component.to_AirLoopHVACOutdoorAirSystem
        if hVACComponent.is_initialized
          hVACComponent = hVACComponent.get

          # set flag that at least one air loop has outdoor air objects
          loops_with_outdoor_air = true

          # get ControllerOutdoorAir
          controller_oa = hVACComponent.getControllerOutdoorAir

          # get ControllerMechanicalVentilation
          controller_mv = controller_oa.controllerMechanicalVentilation # not using this

          if controller_oa.getEconomizerControlType == economizer_type
            # report info about air loop
            runner.registerInfo("#{air_loop.name} already has the requested economizer type of #{economizer_type}.")
          else
            # store starting economizer type
            starting_econo_control_type = controller_oa.getEconomizerControlType

            # set economizer to the requested control type
            controller_oa.setEconomizerControlType(economizer_type)

            # report info about air loop
            runner.registerInfo("Changing Economizer Control Type on #{air_loop.name} from #{starting_econo_control_type} to #{controller_oa.getEconomizerControlType} and adjusting temperature and enthalpy limits per measure arguments.")

            air_loops_changed << air_loop

          end

          # set maximum limit drybulb temperature
          controller_oa.setEconomizerMaximumLimitDryBulbTemperature(OpenStudio.convert(econoMaxDryBulbTemp, 'F', 'C').get)

          # set minimum limit drybulb temperature
          controller_oa.setEconomizerMinimumLimitDryBulbTemperature(OpenStudio.convert(econoMinDryBulbTemp, 'F', 'C').get)

        end
      end
    end

    # Report N/A if none of the air loops had OA systems
    if loops_with_outdoor_air == false
      runner.registerAsNotApplicable('The affected loop(s) do not have any outdoor air objects.')
      return true
    end

    # Report N/A if none of the air loops were changed
    if air_loops_changed.empty?
      runner.registerAsNotApplicable('No air loops had economizers added or removed.')
      return true
    end

    # Report the final condition of model
    runner.registerFinalCondition("#{air_loops_changed.size} air loops now have economizers.")

    return true
  end
end

# this allows the measure to be used by the application
EnableEconomizerControl.new.registerWithApplication
