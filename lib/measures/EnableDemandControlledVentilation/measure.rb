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

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class EnableDemandControlledVentilation < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'Enable Demand Controlled Ventilation'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make choice argument economizer control type
    choices = OpenStudio::StringVector.new
    choices << 'EnableDCV'
    choices << 'DisableDCV'
    choices << 'NoChange'
    dcv_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('dcv_type', choices, true)
    dcv_type.setDisplayName('DCV Type')
    args << dcv_type

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
    dcv_type = runner.getStringArgumentValue('dcv_type', user_arguments)

    # Note if dcv_type == NoChange
    # and register as N/A
    if dcv_type == 'NoChange'
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

    # loop through air loops
    model.getAirLoopHVACs.each do |air_loop|
      # find AirLoopHVACOutdoorAirSystem on loop
      air_loop.supplyComponents.each do |supply_component|
        hVACComponent = supply_component.to_AirLoopHVACOutdoorAirSystem
        if !hVACComponent.empty?
          hVACComponent = hVACComponent.get

          # get ControllerOutdoorAir
          controller_oa = hVACComponent.getControllerOutdoorAir

          # get ControllerMechanicalVentilation
          controller_mv = controller_oa.controllerMechanicalVentilation

          if dcv_type == 'EnableDCV'
            # check if demand control is enabled, if not, then enable it
            if controller_mv.demandControlledVentilation == true
              runner.registerInfo("#{air_loop.name} already has DCV enabled.")
            else
              controller_mv.setDemandControlledVentilation(true)
              runner.registerInfo("Enabling DCV for #{air_loop.name}.")
              air_loops_changed << air_loop
            end
          elsif dcv_type == 'DisableDCV'
            # check if demand control is disabled, if not, then disabled it
            if controller_mv.demandControlledVentilation == false
              runner.registerInfo("#{air_loop.name} already has DCV disabled.")
            else
              controller_mv.setDemandControlledVentilation(false)
              runner.registerInfo("Disabling DCV for #{air_loop.name}.")
              air_loops_changed << air_loop
            end
          end

        end
      end
    end

    # Report N/A if none of the air loops were changed
    if air_loops_changed.empty?
      runner.registerAsNotApplicable('No air loops had DCV enabled or disabled.')
      return true
    end

    # Report final condition of model
    runner.registerFinalCondition("#{air_loops_changed.size} air loops now have demand controlled ventilation enabled.")

    return true
  end
end

# this allows the measure to be use by the application
EnableDemandControlledVentilation.new.registerWithApplication
