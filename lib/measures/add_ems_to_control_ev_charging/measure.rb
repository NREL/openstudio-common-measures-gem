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

# start the measure
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'
class AddEMSToControlEVCharging < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return 'Add EMS to Control EV Charging'
  end

  # human readable description
  def description
    return 'This measure implements a control system to curtail an electric vehicle (EV) charging load to better align EV charging with expected energy production from a solar PV system.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "This measure uses EnergyPlus' Energy Management System to control an electric vehicle (EV) charging load to better align charging power draw with expected energy production from solar PV. There must already be an EV charging load present in the model when this measure is applied, and the measure is configured based on the assumption of a typical office operating schedule."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    curtailment_frac = OpenStudio::Measure::OSArgument.makeDoubleArgument('curtailment_frac', true)
    curtailment_frac.setDisplayName('Fraction by Which to Curtail EV Charging During Load Shifting Events')
    curtailment_frac.setDefaultValue(0.5)
    curtailment_frac.setDescription('Number between 0 and 1 that denotes the fraction by which EV charging')
    args << curtailment_frac

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    curtailment_frac = runner.getDoubleArgumentValue('curtailment_frac', user_arguments)
    if curtailment_frac < 0 || curtailment_frac > 1
      runner.registerError('Curtailment fraction must be between 0 and 1')
      return false
    end

    # Initialize handles
    bldg_handle = nil
    bldg_handle = model.getBuilding.handle

    # Create object for end-of-year-date.
    eoy = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(12), 31, 2006)

    # Find the EV charger object, which will be passed in to the actuator.
    ext_fuel_equip = model.getFacility.exteriorFuelEquipments
    ext_equip_sched = []
    ext_fuel_equip.each do |equip|
      if equip.exteriorFuelEquipmentDefinition.name.to_s.include?('EV') || equip.exteriorFuelEquipmentDefinition.name.to_s.include?('vehicle') || equip.exteriorFuelEquipmentDefinition.name.to_s.include?('Vehicle')
        ext_equip_sched << equip.schedule
      end
    end
    ev_sched = ext_equip_sched [0]
    if ext_equip_sched.empty?
      runner.registerError('No EV charging schedule found. Schedule must include the string "EV", "vehicle", or "Vehicle" in its name.')
      return false
    end
    if ext_equip_sched.length > 1
      runner.registerError('More than one EV charging schedule found. Currently, this measure is capable of handling only one EV charging schedule.')
      return false
    end
    ev_sched_copy = ext_equip_sched [0].clone
    ev_sched_copy.setName('EV Charging Power Draw Copy')

    equip_sched_day = ext_equip_sched [0].to_ScheduleRuleset.get.defaultDaySchedule
    puts(ext_equip_sched [0].to_ScheduleRuleset.get)
    equip_sched_day_default_val = equip_sched_day.values
    puts equip_sched_day_default_val

    # Create a new schedule, scaled by the curtailment fraction
    ev_curtailed_sch = OpenStudio::Model::ScheduleRuleset.new(model)
    ev_curtailed_sch.setName('EV Charging Curtailed Schedule')

    # Default day (use this for weekdays)
    ev_curtailed_sch.defaultDaySchedule.setName('EV Charging Curtailed Default')
    # Loop through all the values and add to schedule
    equip_sched_day_default_val.each_with_index do |value, i|
      time = OpenStudio::Time.new(0, 0, (i + 1) * 15, 0)
      ev_curtailed_sch.defaultDaySchedule.addValue(time, (value * curtailment_frac))
    end
    # Create needed sensors.
    site_solar_rad_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Site Direct Solar Radiation Rate per Area')
    site_solar_rad_sensor.setName('Direct_Solar_Radiation_Rate')

    ev_load_curtailed_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    ev_load_curtailed_sensor.setKeyName('EV Charging Curtailed Schedule')
    ev_load_curtailed_sensor.setName('EV_Load_Curtailed_Sensor')

    ev_load_sched_sensor = OpenStudio::Model::EnergyManagementSystemSensor.new(model, 'Schedule Value')
    ev_load_sched_sensor.setKeyName('EV Charging Power Draw Copy')
    ev_load_sched_sensor.setName('EV_reg_sched_power')

    # Make the needed actuator.
    ev_schedule_actuator = OpenStudio::Model::EnergyManagementSystemActuator.new(ev_sched, 'Schedule:Year', 'Schedule Value')
    ev_schedule_actuator.setName('EVChargeSchedule_Actuator')
    ev_schedule_actuator_handle = ev_schedule_actuator.handle

    # Make the global variables.
    solar_trend = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, 'solartrend')
    arg_dr_state = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, 'argdrstate')
    curtailed_energy_sum = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, 'curtailed_energy_sum')
    curtail_frac = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, 'curtail_frac')
    ev_charge_energy = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, 'EV_charge_energy')
    ev_sched_charge_energy = OpenStudio::Model::EnergyManagementSystemGlobalVariable.new(model, 'EV_sched_charge_energy')

    # Make the trend variables.
    solar_rad_trend = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, site_solar_rad_sensor)
    solar_rad_trend.setName('Solar_Radiation_Trend')
    solar_rad_trend.setEMSVariableName(site_solar_rad_sensor.name.to_s)
    solar_rad_trend.setNumberOfTimestepsToBeLogged(144)

    dr_state_trend = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, arg_dr_state)
    dr_state_trend.setName('DR_State_Trend')
    dr_state_trend.setEMSVariableName(arg_dr_state.name.to_s)

    solar_rad_slope_trend = OpenStudio::Model::EnergyManagementSystemTrendVariable.new(model, solar_trend)
    solar_rad_slope_trend.setName('Solar_Radiation_Slope_Trend')
    solar_rad_slope_trend.setEMSVariableName(solar_trend.name.to_s)

    # Make the needed output variables. Below is using the model and an acutator, or the model and a global variable, which is allowable.
    ev_charge_eff_sched = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ev_schedule_actuator)
    ev_charge_eff_sched.setName('EV Charging Effective Schedule')
    ev_charge_eff_sched.setEMSVariableName(ev_schedule_actuator.name.to_s)

    ev_sched_load = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ev_load_sched_sensor)
    ev_sched_load.setName('EV Charging Regularly Sched Load')
    ev_sched_load.setEMSVariableName(ev_load_sched_sensor.name.to_s)

    dr_state = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, arg_dr_state)
    dr_state.setName('dr_state')
    dr_state.setEMSVariableName(arg_dr_state.name.to_s)

    solar_rad_slope = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, solar_trend)
    solar_rad_slope.setName('solar_radiation_slope_trend')
    solar_rad_slope.setEMSVariableName(solar_trend.name.to_s)

    curtailed_energy_total = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, curtailed_energy_sum)
    curtailed_energy_total.setName('EV Curtailed Energy Total')
    curtailed_energy_total.setEMSVariableName(curtailed_energy_sum.name.to_s)

    ev_charge_energy_output = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ev_charge_energy)
    ev_charge_energy_output.setName('EV Charging Energy')
    ev_charge_energy_output.setEMSVariableName(ev_charge_energy.name.to_s)

    ev_sched_charge_energy_output = OpenStudio::Model::EnergyManagementSystemOutputVariable.new(model, ev_sched_charge_energy)
    ev_sched_charge_energy_output.setName('Scheduled EV Charging Energy')
    ev_sched_charge_energy_output.setEMSVariableName(ev_sched_charge_energy.name.to_s)

    # Make sub-routines.
    # Reset the counter of curtailed energy.
    reset_curtailment_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
    reset_curtailment_subroutine.setName('Initalize_EV_Curtailment')
    reset_curtailment_subroutine.addLine('SET curtailed_energy_sum=0') # Reset this counter to zero.

    # Set the actuator for curtailment.
    curtail_ev_sched_subroutine = OpenStudio::Model::EnergyManagementSystemSubroutine.new(model)
    curtail_ev_sched_subroutine.setName('Set_EV_Sched_Curtailed_Value')
    curtail_ev_sched_subroutine.addLine('SET EVChargeSchedule_Actuator  =EV_Load_Curtailed_Sensor')
    curtail_ev_sched_subroutine.addLine('SET argdrstate = 1')
    curtail_ev_sched_subroutine.addLine('SET curtailed_energy_sum=curtailed_energy_sum + (EV_reg_sched_power-EV_Load_Curtailed_Sensor)')
    curtail_ev_sched_subroutine.addLine('SET ev_charge_energy=ev_charge_energy + EV_Load_Curtailed_Sensor*SystemTimeStep')
    curtail_ev_sched_subroutine.addLine('SET ev_sched_charge_energy=ev_sched_charge_energy + EV_reg_sched_power*SystemTimeStep')

    # Make program.
    execute_ev_curtailment_prgrm = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    execute_ev_curtailment_prgrm.setName('Execute_EV_Curtailment')
    execute_ev_curtailment_prgrm.addLine('IF (CurrentTime==1)')
    execute_ev_curtailment_prgrm.addLine('SET ev_charge_energy=0')
    execute_ev_curtailment_prgrm.addLine('SET ev_sched_charge_energy=0')
    execute_ev_curtailment_prgrm.addLine('ELSEIF (solartrend <0 ) && (CurrentTime<=16) && (CurrentTime>=6) &&(DayofWeek<>1) && (DayofWeek<>7)')
    # execute_ev_curtailment_prgrm.addLine('RUN Initalize_EV_Curtailment')
    execute_ev_curtailment_prgrm.addLine('RUN Set_EV_Sched_Curtailed_Value')
    execute_ev_curtailment_prgrm.addLine('ELSEIF (CurrentTime>16) && (CurrentTime<18.50) && (DayofWeek<>1) && (DayofWeek<>7) ')
    execute_ev_curtailment_prgrm.addLine('SET EVChargeSchedule_Actuator =EV_reg_sched_power + curtailed_energy_sum/((18.75-CurrentTime-SystemTimeStep)/SystemTimeStep)')
    execute_ev_curtailment_prgrm.addLine('SET curtailed_energy_sum =curtailed_energy_sum- curtailed_energy_sum/((18.75-CurrentTime-SystemTimeStep)/SystemTimeStep)')
    execute_ev_curtailment_prgrm.addLine('SET ev_charge_energy =ev_charge_energy + (EV_reg_sched_power + curtailed_energy_sum/((18.75-CurrentTime-SystemTimeStep)/SystemTimeStep))*SystemTimeStep')
    execute_ev_curtailment_prgrm.addLine('SET ev_sched_charge_energy =ev_sched_charge_energy + EV_reg_sched_power*SystemTimeStep')
    execute_ev_curtailment_prgrm.addLine('SET argdrstate = 0')
    execute_ev_curtailment_prgrm.addLine('ELSEIF (CurrentTime==18.50)')
    execute_ev_curtailment_prgrm.addLine('SET curtailed_energy_sum=0')
    execute_ev_curtailment_prgrm.addLine('SET ev_charge_energy =ev_charge_energy + EV_reg_sched_power*SystemTimeStep')
    execute_ev_curtailment_prgrm.addLine('SET ev_sched_charge_energy =ev_sched_charge_energy + EV_reg_sched_power*SystemTimeStep')
    execute_ev_curtailment_prgrm.addLine('ELSEIF (solartrend>=0) && (CurrentTime<18.75)')
    execute_ev_curtailment_prgrm.addLine('SET EVChargeSchedule_Actuator =EV_reg_sched_power + curtailed_energy_sum/((18.75-CurrentTime-SystemTimeStep)/SystemTimeStep)') # Compensate for curtailment
    execute_ev_curtailment_prgrm.addLine('SET curtailed_energy_sum =curtailed_energy_sum- curtailed_energy_sum/((18.75-CurrentTime-SystemTimeStep)/SystemTimeStep)') # Update curtailment counter
    execute_ev_curtailment_prgrm.addLine('SET ev_charge_energy =ev_charge_energy + (EV_reg_sched_power + curtailed_energy_sum/((18.75-CurrentTime-SystemTimeStep)/SystemTimeStep))*SystemTimeStep')
    execute_ev_curtailment_prgrm.addLine('SET ev_sched_charge_energy =ev_sched_charge_energy + EV_reg_sched_power*SystemTimeStep')
    execute_ev_curtailment_prgrm.addLine('SET argdrstate = 0')
    execute_ev_curtailment_prgrm.addLine('ELSE')
    execute_ev_curtailment_prgrm.addLine('SET EVChargeSchedule_Actuator  = Null')
    execute_ev_curtailment_prgrm.addLine('SET ev_sched_charge_energy =ev_sched_charge_energy + EV_reg_sched_power*SystemTimeStep')
    execute_ev_curtailment_prgrm.addLine('SET ev_charge_energy =ev_charge_energy + EV_reg_sched_power*SystemTimeStep')
    execute_ev_curtailment_prgrm.addLine('SET argdrstate = 0')
    execute_ev_curtailment_prgrm.addLine('ENDIF')

    solar_trend_prgrm = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    solar_trend_prgrm.setName('Set_Solar_Trend')
    solar_trend_prgrm.addLine('SET solartrend  =@TrendDirection Solar_Radiation_Trend 2')

    set_demand_threshold_prgrm = OpenStudio::Model::EnergyManagementSystemProgram.new(model)
    set_demand_threshold_prgrm.setName('Set_Demand_Threshold')
    set_demand_threshold_prgrm.addLine('SET curtailed_energy_sum =0')
    set_demand_threshold_prgrm.addLine('SET ev_charge_energy =0')
    set_demand_threshold_prgrm.addLine('SET ev_sched_charge_energy =0')

    # Add program calling managers.
    ev_curtailment_main_calling_mgr = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    ev_curtailment_main_calling_mgr.setName('EV_Curtailment')
    ev_curtailment_main_calling_mgr.setCallingPoint('BeginTimestepBeforePredictor')

    ev_curtailment_main_calling_mgr.setProgram(solar_trend_prgrm, 0)
    ev_curtailment_main_calling_mgr.setProgram(execute_ev_curtailment_prgrm, 1)

    set_input_vars_mgr = OpenStudio::Model::EnergyManagementSystemProgramCallingManager.new(model)
    set_input_vars_mgr.setName('Set_input_vars')
    set_input_vars_mgr.setCallingPoint('BeginNewEnvironment')
    set_input_vars_mgr.setProgram(set_demand_threshold_prgrm, 0)

    # Add output variables
    outputVariable = OpenStudio::Model::OutputVariable.new('dr_state', model)
    outputVariable.setReportingFrequency('timestep')

    outputVariable = OpenStudio::Model::OutputVariable.new('Schedule Value', model)
    outputVariable.setReportingFrequency('timestep')
    outputVariable.setKeyValue('EV Charging Power Draw')

    outputVariable = OpenStudio::Model::OutputVariable.new('Schedule Value', model)
    outputVariable.setReportingFrequency('timestep')
    outputVariable.setKeyValue('EV Charging Power Draw Copy')

    outputVariable = OpenStudio::Model::OutputVariable.new('EV Curtailed Energy Total', model)
    outputVariable.setReportingFrequency('timestep')

    outputVariable = OpenStudio::Model::OutputVariable.new('Scheduled EV Charging Energy', model)
    outputVariable.setReportingFrequency('timestep')

    outputVariable = OpenStudio::Model::OutputVariable.new('EV Charging Energy', model)
    outputVariable.setReportingFrequency('timestep')

    return true
  end
end

# register the measure to be used by the application
AddEMSToControlEVCharging.new.registerWithApplication
