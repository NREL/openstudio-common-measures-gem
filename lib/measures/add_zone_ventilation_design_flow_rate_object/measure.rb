

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
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class AddZoneVentilationDesignFlowRateObject < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Add Zone Ventilation Design Flow Rate Object'
  end

  # human readable description
  def description
    return 'This will allow you to add a ZoneVentilation:DesignFlowRate object into your model in a specified zone. The ventilation type is exposed as an argument but the design flow rate calculation method is set to design flow rate. A number of other object inputs are exposed as arguments'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This is simple implementation ment to expose the object to users. More complex use case specific versions will likely be developed in the future that may add multiple zone ventilation objects as well as zone mixing objects'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # populate choice argument for thermal zones in the model
    zone_handles = OpenStudio::StringVector.new
    zone_display_names = OpenStudio::StringVector.new

    # putting zone names into hash
    zone_hash = {}
    model.getThermalZones.each do |zone|
      zone_hash[zone.name.to_s] = zone
    end

    # looping through sorted hash of zones
    zone_hash.sort.map do |zone_name, zone|
      zone_handles << zone.handle.to_s
      zone_display_names << zone_name
    end

    # make an argument for zones
    zone = OpenStudio::Measure::OSArgument.makeChoiceArgument('zone', zone_handles, zone_display_names, true)
    zone.setDisplayName('Choose Thermal Zones to add zone ventilation to')
    args << zone

    # populate choice argument for schedules in the model
    sch_handles = OpenStudio::StringVector.new
    sch_display_names = OpenStudio::StringVector.new

    # putting schedule names into hash
    sch_hash = {}
    model.getSchedules.each do |sch|
      sch_hash[sch.name.to_s] = sch
    end

    # looping through sorted hash of schedules
    sch_hash.sort.map do |sch_name, sch|
      if !sch.scheduleTypeLimits.empty?
        # unitType = sch.scheduleTypeLimits.get.unitType
        # puts "#{sch.name}, #{unitType}"
        # if unitType == "Temperature"   # todo - what is correct type for fractional
        sch_handles << sch.handle.to_s
        sch_display_names << sch_name
        # end
      end
    end

    # add empty handle to string vector with schedules
    sch_handles << OpenStudio.toUUID('').to_s

    # make an argument for cooling schedule
    vent_sch = OpenStudio::Measure::OSArgument.makeChoiceArgument('vent_sch', sch_handles, sch_display_names, true)
    vent_sch.setDisplayName('Choose Schedulew')
    args << vent_sch

    # make choice argument for vent_type
    choices = OpenStudio::StringVector.new
    choices << 'Natural'
    choices << 'Exhaust'
    choices << 'Intake'
    choices << 'Balanced'
    vent_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('vent_type', choices, true)
    vent_type.setDisplayName('Ventilation Type')
    vent_type.setDefaultValue('Natural')
    args << vent_type

    # make double argument for sillHeight
    design_flow_rate = OpenStudio::Measure::OSArgument.makeDoubleArgument('design_flow_rate', true)
    design_flow_rate.setDisplayName('Design Flow Rate')
    design_flow_rate.setUnits('cfm')
    args << design_flow_rate

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
    zone = runner.getOptionalWorkspaceObjectChoiceValue('zone', user_arguments, model) # model is passed in because of argument type
    vent_sch = runner.getOptionalWorkspaceObjectChoiceValue('vent_sch', user_arguments, model) # model is passed in because of argument type
    vent_type = runner.getStringArgumentValue('vent_type', user_arguments)
    design_flow_rate = runner.getDoubleArgumentValue('design_flow_rate', user_arguments)
    design_flow_rate_si = OpenStudio.convert(design_flow_rate, 'cfm', 'm^3/s').get

    # check the zone selection for reasonableness
    if zone.empty?
      handle = runner.getStringArgumentValue('zone', user_arguments)
      if handle.empty?
        runner.registerError('No thermal zone was chosen.')
        return false
      else
        runner.registerError("The selected thermal zone with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
        return false
      end
    else
      if !zone.get.to_ThermalZone.empty?
        zone = zone.get.to_ThermalZone.get
      else
        runner.registerError('Script Error - argument not showing up as thermal zone.')
        return false
      end
    end
    if vent_sch.empty?
      handle = runner.getStringArgumentValue('vent_sch', user_arguments)
      if handle.empty?
        runner.registerError('No schedule was chosen.')
        return false
      else
        runner.registerError("The selected schedule with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
        return false
      end
    else
      if !vent_sch.get.to_Schedule.empty?
        vent_sch = vent_sch.get.to_Schedule.get
      else
        runner.registerError('Script Error - argument not showing up as schedule.')
        return false
      end
    end

    # report initial condition of model
    runner.registerInitialCondition("The building started with #{model.getZoneVentilationDesignFlowRates.size} zone ventilation design flow rate objects.")

    # add zone ventilation object
    zone_ventilation = OpenStudio::Model::ZoneVentilationDesignFlowRate.new(model)
    zone_ventilation.addToThermalZone(zone)
    zone_ventilation.setVentilationType(vent_type)
    zone_ventilation.setDesignFlowRateCalculationMethod('Flow/Zone')
    zone_ventilation.setDesignFlowRate(design_flow_rate_si)
    zone_ventilation.setSchedule(vent_sch)
    runner.registerInfo('Creating zone ventilation design flow rate object with ventilation type of ')

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getZoneVentilationDesignFlowRates.size} zone ventilation design flow rate objects.")

    return true
  end
end

# register the measure to be used by the application
AddZoneVentilationDesignFlowRateObject.new.registerWithApplication
