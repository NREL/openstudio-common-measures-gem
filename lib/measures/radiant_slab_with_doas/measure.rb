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

require 'openstudio-standards'

# start the measure
class RadiantSlabWithDoas < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Radiant Slab with DOAS'
  end

  # human readable description
  def description
    return 'Adds a radiant slab with DOAS ventilation system to the model.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'This measure adds either a radiant floor slab or radiant ceiling slab with dedicated outdoor air system to conditioned zones in the model.
Radiant systems are comfortable with wider zone air temperature range. Use the CBE Thermal Comfort Tool or other method to set thermostat setpoint temperatures.
This measure optionally removes existing HVAC systems (recommended).
This measure is dependent on an ASHRAE climate zone to set insulation and design supply temperature levels, so make sure this is set in the site parameters of the model.
Plant equipment options are an Air Source Heat Pump or a Boiler for hot water, and an Air Cooled Chiller or Water Cooled Chiller for chilled water.
The Air Source Heat Pump object uses a user-defined plant component in EnergyPlus and may not be compatible with several reporting measures, including the *Enable Detailed Output for Each Node in a Loop* measure.
If Water Cooled Chiller is selected, the measure will add a condenser loop with a variable speed cooling tower, and optionally enable water-side economizing when wet bulb conditions allow.
By default, the slab system does not include carpet. Carpet greatly reduces the heat transfer capacity of the radiant system.  If carpet is preferred, a ceiling-type slab and no lockout are recommended to avoid unmet hours.
The measure includes several control parameters for radiant system operation. Use the defaults unless you have strong reasons to deviate from them.
This measure runs a sizing run to set equipment efficiency values, so it may take up to a few minutes to run.
This measure adds many EnergyManagementSystem objects to the model. **DO NOT** change design days after running this measure.  Adding additional HVAC measures after applying this measure may break the model.
Radiant systems are particularly limited in cooling capacity and the model may have many unmet hours as a result.
To reduce unmet hours, use an expanded comfort range as mentioned above, remove carpet, reduce internal loads, reduce solar and envelope gains during peak times, or disable the lockout.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make bool argument to remove existing HVAC system
    remove_existing_hvac = OpenStudio::Measure::OSArgument.makeBoolArgument('remove_existing_hvac', true)
    remove_existing_hvac.setDisplayName('Remove existing HVAC system (keeps service water heating and zone exhaust fans)')
    remove_existing_hvac.setDefaultValue(true)
    args << remove_existing_hvac

    # make an argument for heating plant type
    heating_plant_types = OpenStudio::StringVector.new
    heating_plant_types << 'Air Source Heat Pump'
    heating_plant_types << 'Boiler'
    heating_plant_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('heating_plant_type', heating_plant_types, true)
    heating_plant_type.setDisplayName('Heating Plant Type')
    heating_plant_type.setDefaultValue('Air Source Heat Pump')
    args << heating_plant_type

    # make an argument for cooling plant type
    cooling_plant_types = OpenStudio::StringVector.new
    cooling_plant_types << 'Air Cooled Chiller'
    cooling_plant_types << 'Water Cooled Chiller'
    cooling_plant_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('cooling_plant_type', cooling_plant_types, true)
    cooling_plant_type.setDisplayName('Cooling Plant Type')
    cooling_plant_type.setDefaultValue('Air Cooled Chiller')
    args << cooling_plant_type

    # make string argument for water-side economizing if water-cooled chiller
    economizer_types = OpenStudio::StringVector.new
    economizer_types << 'none'
    economizer_types << 'integrated'
    economizer_types << 'non-integrated'
    waterside_economizer = OpenStudio::Measure::OSArgument.makeChoiceArgument('waterside_economizer', economizer_types, true)
    waterside_economizer.setDisplayName('Water-side economizer (water cooled chiller only)')
    waterside_economizer.setDefaultValue('none')
    args << waterside_economizer

    # make an argument for radiant system type
    radiant_types = OpenStudio::StringVector.new
    radiant_types << 'floor'
    radiant_types << 'ceiling'
    radiant_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('radiant_type', radiant_types, true)
    radiant_type.setDisplayName('Radiant System Type')
    radiant_type.setDefaultValue('floor')
    args << radiant_type

    # make and argument for adding carpet
    include_carpet = OpenStudio::Measure::OSArgument.makeBoolArgument('include_carpet', true)
    include_carpet.setDisplayName('Include carpet over the radiant slab')
    include_carpet.setDescription('Only applicable in radiant floor systems. This will greatly reduce system effectiveness and controllability.')
    include_carpet.setDefaultValue(false)
    args << include_carpet

    # make an argument for control strategy
    control_strategys = OpenStudio::StringVector.new
    control_strategys << 'proportional_control'
    control_strategy = OpenStudio::Measure::OSArgument.makeChoiceArgument('control_strategy', control_strategys, true)
    control_strategy.setDisplayName('Control Strategy')
    control_strategy.setDefaultValue('proportional_control')
    args << control_strategy

    # make an argument for proportional gain
    proportional_gain = OpenStudio::Measure::OSArgument.makeDoubleArgument('proportional_gain', true)
    proportional_gain.setDisplayName('Proportional Gain')
    proportional_gain.setDefaultValue(0.3)
    args << proportional_gain

    # make an argument for minimum operating hours
    minimum_operation = OpenStudio::Measure::OSArgument.makeDoubleArgument('minimum_operation', true)
    minimum_operation.setDisplayName('Minimum Operating Hours')
    minimum_operation.setDescription('Fractional Hours Allowed, e.g. 30 min = 0.5')
    minimum_operation.setDefaultValue(1.0)
    args << minimum_operation

    # make an argument for switch over time
    switch_over_time = OpenStudio::Measure::OSArgument.makeDoubleArgument('switch_over_time', true)
    switch_over_time.setDisplayName('Switch Over Time')
    switch_over_time.setDescription('Minimum time limitation for when the system can switch between heating and cooling.  Fractional hours allowed, e.g. 30 min = 0.5.')
    switch_over_time.setDefaultValue(24.0)
    args << switch_over_time

    # make and argument for including radiant lockout
    radiant_lockout = OpenStudio::Measure::OSArgument.makeBoolArgument('radiant_lockout', true)
    radiant_lockout.setDisplayName('Enable radiant lockout')
    radiant_lockout.setDescription('Lockout the radiant system to avoid operating during peak hours.')
    radiant_lockout.setDefaultValue(false)
    args << radiant_lockout

    # make an argument for lockout start time
    lockout_start_time = OpenStudio::Measure::OSArgument.makeDoubleArgument('lockout_start_time', true)
    lockout_start_time.setDisplayName('Lockout Start Time')
    lockout_start_time.setDescription('Decimal hour of when radiant lockout starts.  Fractional hours allowed, e.g. 30 min = 0.5.')
    lockout_start_time.setDefaultValue(12.0)
    args << lockout_start_time

    # make an argument for lockout end time
    lockout_end_time = OpenStudio::Measure::OSArgument.makeDoubleArgument('lockout_end_time', true)
    lockout_end_time.setDisplayName('Lockout End Time')
    lockout_end_time.setDescription('Decimal hour of when radiant lockout ends.  Fractional hours allowed, e.g. 30 min = 0.5.')
    lockout_end_time.setDefaultValue(20.0)
    args << lockout_end_time

    # make and argument for output variables
    add_output_variables = OpenStudio::Measure::OSArgument.makeBoolArgument('add_output_variables', true)
    add_output_variables.setDisplayName('Add output variables for radiant system')
    add_output_variables.setDefaultValue(true)
    args << add_output_variables

    # make an argument for standards template
    standards_templates = OpenStudio::StringVector.new
    standards_templates << '90.1-2013'
    standards_templates << 'DEER 2017'
    standards_templates << 'DEER 2020'
    standards_template = OpenStudio::Measure::OSArgument.makeChoiceArgument('standards_template', standards_templates, true)
    standards_template.setDisplayName('Standards Template')
    standards_template.setDescription('Standards template to use for HVAC equipment efficiencies and controls.')
    standards_template.setDefaultValue('90.1-2013')
    args << standards_template

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign user inputs
    remove_existing_hvac = runner.getBoolArgumentValue('remove_existing_hvac', user_arguments)
    heating_plant_type = runner.getStringArgumentValue('heating_plant_type', user_arguments)
    cooling_plant_type = runner.getStringArgumentValue('cooling_plant_type', user_arguments)
    waterside_economizer = runner.getStringArgumentValue('waterside_economizer', user_arguments)
    radiant_type = runner.getStringArgumentValue('radiant_type', user_arguments)
    include_carpet = runner.getBoolArgumentValue('include_carpet', user_arguments)
    control_strategy = runner.getStringArgumentValue('control_strategy', user_arguments)
    proportional_gain = runner.getDoubleArgumentValue('proportional_gain', user_arguments)
    minimum_operation = runner.getDoubleArgumentValue('minimum_operation', user_arguments)
    switch_over_time = runner.getDoubleArgumentValue('switch_over_time', user_arguments)
    radiant_lockout = runner.getBoolArgumentValue('radiant_lockout', user_arguments)
    lockout_start_time = runner.getDoubleArgumentValue('lockout_start_time', user_arguments)
    lockout_end_time = runner.getDoubleArgumentValue('lockout_end_time', user_arguments)
    add_output_variables = runner.getBoolArgumentValue('add_output_variables', user_arguments)
    standards_template = runner.getStringArgumentValue('standards_template', user_arguments)

    # standard to access methods in openstudio-standards
    std = Standard.build(standards_template)

    # remove existing hvac systems
    if remove_existing_hvac
      runner.registerInfo('Removing existing HVAC systems from the model')
      std.remove_HVAC(model)
    end

    # exclude plenum zones, zones without thermostats, and zones with no floor area
    conditioned_zones = []
    model.getThermalZones.each do |zone|
      next if std.thermal_zone_plenum?(zone)
      next if !std.thermal_zone_heated?(zone) && !std.thermal_zone_cooled?(zone)
      conditioned_zones << zone
    end

    # make sure the model has conditioned zones
    if conditioned_zones.empty?
      runner.registerAsNotApplicable('No conditioned zones identified in model. Make sure thermostats are assigned to zones.')
      return false
    end

    # get the climate zone
    climate_zone_obj = model.getClimateZones.getClimateZone('ASHRAE', 2006)
    if climate_zone_obj.empty
      climate_zone_obj = model.getClimateZones.getClimateZone('ASHRAE', 2013)
    end

    if climate_zone_obj.empty || climate_zone_obj.value == ''
      runner.registerError('Please assign an ASHRAE climate zone to the model before running the measure.')
      return false
    else
      climate_zone = climate_zone_obj.value
    end

    # get the radiant hot water temperature based on the climate zone
    case climate_zone
    when '1'
      radiant_htg_dsgn_sup_wtr_temp_f = 90.0
    when '2', '2A', '2B', 'CEC15'
      radiant_htg_dsgn_sup_wtr_temp_f = 100.0
    when '3', '3A', '3B', '3C', 'CEC3', 'CEC4', 'CEC5', 'CEC6', 'CEC7', 'CEC8', 'CEC9', 'CEC10', 'CEC11', 'CEC12', 'CEC13', 'CEC14'
      radiant_htg_dsgn_sup_wtr_temp_f = 100.0
    when '4', '4A', '4B', '4C', 'CEC1', 'CEC2'
      radiant_htg_dsgn_sup_wtr_temp_f = 100.0
    when '5', '5A', '5B', '5C', 'CEC16'
      radiant_htg_dsgn_sup_wtr_temp_f = 110.0
    when '6', '6A', '6B'
      radiant_htg_dsgn_sup_wtr_temp_f = 120.0
    when '7', '8'
      radiant_htg_dsgn_sup_wtr_temp_f = 120.0
    else # default to 4
      radiant_htg_dsgn_sup_wtr_temp_f = 100.0
    end
    runner.registerInitialCondition("This measure will add radiant systems to #{conditioned_zones.size} conditioned zones with a hot water loop served by a #{heating_plant_type} and chilled water loop served by a #{cooling_plant_type}.")
    runner.registerInfo("Based on model climate zone #{climate_zone}, using #{radiant_htg_dsgn_sup_wtr_temp_f}F heating supply water temperature.")

    # establish hot water and chilled water loops
    case heating_plant_type
    when 'Air Source Heat Pump'
      boiler_fuel_type = 'ASHP'
    when 'Boiler'
      boiler_fuel_type = 'NaturalGas'
    end
    hot_water_loop = std.model_add_hw_loop(model, boiler_fuel_type, dsgn_sup_wtr_temp: radiant_htg_dsgn_sup_wtr_temp_f, dsgn_sup_wtr_temp_delt: 10.0)

    case cooling_plant_type
    when 'Air Cooled Chiller'
      # make chilled water loop
      chilled_water_loop = std.model_add_chw_loop(model,
                                                  chw_pumping_type: 'const_pri_var_sec',
                                                  dsgn_sup_wtr_temp: 55.0,
                                                  dsgn_sup_wtr_temp_delt: 5.0,
                                                  chiller_cooling_type: 'AirCooled')
    when 'Water Cooled Chiller'
      # make condenser water loop
      fan_type = std.model_cw_loop_cooling_tower_fan_type(model)
      condenser_water_loop = std.model_add_cw_loop(model,
                                                   cooling_tower_type: 'Open Cooling Tower',
                                                   cooling_tower_fan_type: 'Propeller or Axial',
                                                   cooling_tower_capacity_control: fan_type,
                                                   number_of_cells_per_tower: 1,
                                                   number_cooling_towers: 1)
      # make chilled water loop
      chilled_water_loop = std.model_add_chw_loop(model,
                                                  chw_pumping_type: 'const_pri_var_sec',
                                                  dsgn_sup_wtr_temp: 55.0,
                                                  dsgn_sup_wtr_temp_delt: 5.0,
                                                  chiller_cooling_type: 'WaterCooled',
                                                  condenser_water_loop: condenser_water_loop,
                                                  waterside_economizer: waterside_economizer)
    end

    # add radiant system to conditioned zones
    radiant_loops = std.model_add_low_temp_radiant(model, conditioned_zones, hot_water_loop, chilled_water_loop,
                                                   radiant_type: radiant_type,
                                                   include_carpet: include_carpet,
                                                   control_strategy: control_strategy,
                                                   proportional_gain: proportional_gain,
                                                   minimum_operation: minimum_operation,
                                                   switch_over_time: switch_over_time,
                                                   radiant_lockout: radiant_lockout,
                                                   radiant_lockout_start_time: lockout_start_time,
                                                   radiant_lockout_end_time: lockout_end_time)

    # add DOAS system to conditioned zones
    std.model_add_doas(model, conditioned_zones)
    std.rename_air_loop_nodes(model)

    # set the heating and cooling sizing parameters
    std.model_apply_prm_sizing_parameters(model)

    runner.registerInfo("Adjusting HVAC equipment efficiencies and controls to follow template #{standards_template}.")

    # perform a sizing run
    if std.model_run_sizing_run(model, "#{Dir.pwd}/radiant_sizing_run") == false
      runner.registerError('Sizing run failed. See errors in sizing run directory of this measure')
      return false
    end

    # Apply the HVAC efficiency standard
    std.model_apply_hvac_efficiency_standard(model, climate_zone)

    # add output variables
    vars = []
    if add_output_variables
      # site outdoor drybulb temperature
      vars << OpenStudio::Model::OutputVariable.new('Site Outdoor Air Drybulb Temperature', model)

      # zone hvac low temperature radiant system object variables
      vars << OpenStudio::Model::OutputVariable.new('Zone Radiant HVAC Cooling Energy', model)
      vars << OpenStudio::Model::OutputVariable.new('Zone Radiant HVAC Heating Energy', model)
      vars << OpenStudio::Model::OutputVariable.new('Zone Radiant HVAC Inlet Temperature', model)
      vars << OpenStudio::Model::OutputVariable.new('Zone Radiant HVAC Outlet Temperature', model)
      vars << OpenStudio::Model::OutputVariable.new('Zone Radiant HVAC Mass Flow Rate', model)

      # plant loop variables
      var = OpenStudio::Model::OutputVariable.new('System Node Mass Flow Rate', model)
      var.setKeyValue('Chilled Water Loop Supply Outlet Node')
      vars << var
      var = OpenStudio::Model::OutputVariable.new('System Node Mass Flow Rate', model)
      var.setKeyValue('Hot Water Loop Supply Outlet Node')
      vars << var
      var = OpenStudio::Model::OutputVariable.new('System Node Temperature', model)
      var.setKeyValue('Chilled Water Loop Supply Outlet Node')
      vars << var
      var = OpenStudio::Model::OutputVariable.new('System Node Temperature', model)
      var.setKeyValue('Hot Water Loop Supply Outlet Node')
      vars << var
      var = OpenStudio::Model::OutputVariable.new('System Node Setpoint Temperature', model)
      var.setKeyValue('Chilled Water Loop Supply Outlet Node')
      vars << var
      var = OpenStudio::Model::OutputVariable.new('System Node Setpoint Temperature', model)
      var.setKeyValue('Hot Water Loop Supply Outlet Node')
      vars << var

      conditioned_space_names = []
      conditioned_zones.each do |zone|
        zone.spaces.each { |space| conditioned_space_names << space.name }
      end

      # radiant surface temperatures
      model.getSurfaces.each do |surface|
        next if radiant_type == 'floor' && surface.surfaceType != 'Floor'
        next if radiant_type == 'ceiling' && surface.surfaceType != 'RoofCeiling'
        next unless surface.space.is_initialized
        surface_space_name = surface.space.get.name.to_s
        next unless conditioned_space_names.include? surface_space_name
        var = OpenStudio::Model::OutputVariable.new('Surface Inside Face Temperature', model)
        var.setKeyValue(surface.name.to_s)
        vars << var
      end

      # set to timestep
      vars.each { |var| var.setReportingFrequency('Timestep') }
    end

    # runner register final condition
    runner.registerFinalCondition("This measure created #{model.getZoneHVACLowTempRadiantVarFlows.size} radiant #{radiant_type} objects.")

    return true
  end
end

# register the measure to be used by the application
RadiantSlabWithDoas.new.registerWithApplication
