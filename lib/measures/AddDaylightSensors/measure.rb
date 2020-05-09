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

# start the measure
class AddDaylightSensors < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    return 'Add Daylight Sensor at the Center of Spaces with a Specified Space Type Assigned'
  end

  # human readable description
  def description
    return 'This measure will add daylighting controls to spaces that that have space types assigned with names containing the string in the argument. You can also add a cost per space for sensors added to the model.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "Make an array of the spaces that meet the criteria. Locate the sensor x and y values by averaging the min and max X and Y values from floor surfaces in the space. If a space already has a daylighting control, do not add a new one and leave the original in place. Warn the user if the space isn't assigned to a thermal zone, or if the space doesn't have any translucent surfaces. Note that the cost is added to the space not the sensor. If the sensor is removed at a later date, the cost will remain."
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make a choice argument for model objects
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    # putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    # looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key, value|
      # only include if space type is used in the model
      if !value.spaces.empty?
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end

    # make a choice argument for space type
    space_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('space_type', space_type_handles, space_type_display_names, true)
    space_type.setDisplayName('Add Daylight Sensors to Spaces of This Space Type')
    args << space_type

    # make an argument for setpoint
    setpoint = OpenStudio::Measure::OSArgument.makeDoubleArgument('setpoint', true)
    setpoint.setDisplayName('Daylighting Setpoint')
    setpoint.setUnits('fc')
    setpoint.setDefaultValue(45.0)
    args << setpoint

    # make an argument for control_type
    chs = OpenStudio::StringVector.new
    chs << 'None'
    chs << 'Continuous'
    chs << 'Stepped'
    chs << 'Continuous/Off'
    control_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('control_type', chs)
    control_type.setDisplayName('Daylighting Control Type')
    control_type.setDefaultValue('Continuous/Off')
    args << control_type

    # make an argument for min_power_fraction
    min_power_fraction = OpenStudio::Measure::OSArgument.makeDoubleArgument('min_power_fraction', true)
    min_power_fraction.setDisplayName('Daylighting Minimum Input Power Fraction')
    min_power_fraction.setDescription('min = 0 max = 0.6')
    min_power_fraction.setDefaultValue(0.3)
    args << min_power_fraction

    # make an argument for min_light_fraction
    min_light_fraction = OpenStudio::Measure::OSArgument.makeDoubleArgument('min_light_fraction', true)
    min_light_fraction.setDisplayName('Daylighting Minimum Light Output Fraction')
    min_light_fraction.setDescription('min = 0 max = 0.6')
    min_light_fraction.setDefaultValue(0.2)
    args << min_light_fraction

    # make an argument for fraction_zone_controlled
    fraction_zone_controlled = OpenStudio::Measure::OSArgument.makeDoubleArgument('fraction_zone_controlled', true)
    fraction_zone_controlled.setDisplayName('Fraction of zone controlled by daylight sensors')
    fraction_zone_controlled.setDefaultValue(1.0)
    args << fraction_zone_controlled

    # make an argument for height
    height = OpenStudio::Measure::OSArgument.makeDoubleArgument('height', true)
    height.setDisplayName('Sensor Height')
    height.setUnits('inches')
    height.setDefaultValue(30.0)
    args << height

    # make an argument for material and installation cost
    material_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost', true)
    material_cost.setDisplayName('Material and Installation Costs per Space for Daylight Sensor')
    material_cost.setUnits('$')
    material_cost.setDefaultValue(0.0)
    args << material_cost

    # make an argument for demolition cost
    demolition_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('demolition_cost', true)
    demolition_cost.setDisplayName('Demolition Costs per Space for Daylight Sensor')
    demolition_cost.setUnits('$')
    demolition_cost.setDefaultValue(0.0)
    args << demolition_cost

    # make an argument for duration in years until costs start
    years_until_costs_start = OpenStudio::Measure::OSArgument.makeIntegerArgument('years_until_costs_start', true)
    years_until_costs_start.setDisplayName('Years Until Costs Start')
    years_until_costs_start.setUnits('whole years')
    years_until_costs_start.setDefaultValue(0)
    args << years_until_costs_start

    # make an argument to determine if demolition costs should be included in initial construction
    demo_cost_initial_const = OpenStudio::Measure::OSArgument.makeBoolArgument('demo_cost_initial_const', true)
    demo_cost_initial_const.setDisplayName('Demolition Costs Occur During Initial Construction')
    demo_cost_initial_const.setDefaultValue(false)
    args << demo_cost_initial_const

    # make an argument for expected life
    expected_life = OpenStudio::Measure::OSArgument.makeIntegerArgument('expected_life', true)
    expected_life.setDisplayName('Expected Life')
    expected_life.setUnits('whole years')
    expected_life.setDefaultValue(20)
    args << expected_life

    # make an argument for o&m cost
    om_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('om_cost', true)
    om_cost.setDisplayName('O & M Costs per Space for Daylight Sensor')
    om_cost.setUnits('$')
    om_cost.setDefaultValue(0.0)
    args << om_cost

    # make an argument for o&m frequency
    om_frequency = OpenStudio::Measure::OSArgument.makeIntegerArgument('om_frequency', true)
    om_frequency.setDisplayName('O & M Frequency')
    om_frequency.setUnits('whole years')
    om_frequency.setDefaultValue(1)
    args << om_frequency

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
    space_type = runner.getOptionalWorkspaceObjectChoiceValue('space_type', user_arguments, model)
    setpoint = runner.getDoubleArgumentValue('setpoint', user_arguments)
    control_type = runner.getStringArgumentValue('control_type', user_arguments)
    min_power_fraction = runner.getDoubleArgumentValue('min_power_fraction', user_arguments)
    min_light_fraction = runner.getDoubleArgumentValue('min_light_fraction', user_arguments)
    fraction_zone_controlled = runner.getDoubleArgumentValue('fraction_zone_controlled', user_arguments)
    height = runner.getDoubleArgumentValue('height', user_arguments)
    material_cost = runner.getDoubleArgumentValue('material_cost', user_arguments)
    demolition_cost = runner.getDoubleArgumentValue('demolition_cost', user_arguments)
    years_until_costs_start = runner.getIntegerArgumentValue('years_until_costs_start', user_arguments)
    demo_cost_initial_const = runner.getBoolArgumentValue('demo_cost_initial_const', user_arguments)
    expected_life = runner.getIntegerArgumentValue('expected_life', user_arguments)
    om_cost = runner.getDoubleArgumentValue('om_cost', user_arguments)
    om_frequency = runner.getIntegerArgumentValue('om_frequency', user_arguments)

    # check the space_type for reasonableness
    if space_type.empty?
      handle = runner.getStringArgumentValue('space_type', user_arguments)
      if handle.empty?
        runner.registerError('No SpaceType was chosen.')
      else
        runner.registerError("The selected space type with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if !space_type.get.to_SpaceType.empty?
        space_type = space_type.get.to_SpaceType.get
      else
        runner.registerError('Script Error - argument not showing up as space type.')
        return false
      end
    end

    # check the setpoint for reasonableness
    if (setpoint < 0) || (setpoint > 9999) # dfg need input on good value
      runner.registerError("A setpoint of #{setpoint} foot-candles is outside the measure limit.")
      return false
    elsif setpoint > 999
      runner.registerWarning("A setpoint of #{setpoint} foot-candles is abnormally high.") # dfg need input on good value
    end

    # check the min_power_fraction for reasonableness
    if (min_power_fraction < 0.0) || (min_power_fraction > 0.6)
      runner.registerError("The requested minimum input power fraction of #{min_power_fraction} for continuous dimming control is outside the acceptable range of 0 to 0.6.")
      return false
    end

    # check the min_light_fraction for reasonableness
    if (min_light_fraction < 0.0) || (min_light_fraction > 0.6)
      runner.registerError("The requested minimum light output fraction of #{min_light_fraction} for continuous dimming control is outside the acceptable range of 0 to 0.6.")
      return false
    end

    # check the height for reasonableness
    if (height < -360) || (height > 360) # neg ok because space origin may not be floor
      runner.registerError("A setpoint of #{height} inches is outside the measure limit.")
      return false
    elsif height > 72
      runner.registerWarning("A setpoint of #{height} inches is abnormally high.")
      elseif height < 0
      runner.registerWarning('Typically the sensor height should be a positive number, however if your space origin is above the floor then a negative sensor height may be approriate.')
    end

    # set flags to use later
    costs_requested = false
    warning_cost_assign_to_space = false

    # check costs for reasonableness
    if material_cost.abs + demolition_cost.abs + om_cost.abs == 0
      runner.registerInfo('No costs were requested for Daylight Sensors.')
    else
      costs_requested = true
    end

    # check lifecycle arguments for reasonableness
    if (years_until_costs_start < 0) && (years_until_costs_start > expected_life)
      runner.registerError('Years until costs start should be a non-negative integer less than Expected Life.')
    end
    if (expected_life < 1) && (expected_life > 100)
      runner.registerError('Choose an integer greater than 0 and less than or equal to 100 for Expected Life.')
    end
    if om_frequency < 1
      runner.registerError('Choose an integer greater than 0 for O & M Frequency.')
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

    # helper that loops through lifecycle costs getting total costs under "Construction" or "Salvage" category and add to counter if occurs during year 0
    def get_total_costs_for_objects(objects)
      counter = 0
      objects.each do |object|
        object_LCCs = object.lifeCycleCosts
        object_LCCs.each do |object_LCC|
          if (object_LCC.category == 'Construction') || (object_LCC.category == 'Salvage')
            if object_LCC.yearsFromStart == 0
              counter += object_LCC.totalCost
            end
          end
        end
      end
      return counter
    end

    # unit conversion from IP units to SI units
    setpoint_si = OpenStudio.convert(setpoint, 'fc', 'lux').get
    height_si = OpenStudio.convert(height, 'in', 'm').get

    # variable to tally the area to which the overall measure is applied
    area = 0
    # variables to aggregate the number of sensors installed and the area affected
    sensor_count = 0
    sensor_area = 0
    spaces_using_space_type = space_type.spaces
    # array with subset of spaces
    spaces_using_space_type_in_zones_without_sensors = []
    affected_zones = []
    affected_zone_names = []
    # hash to hold sensor objects
    new_sensor_objects = {}

    # reporting initial condition of model
    starting_spaces = model.getSpaces
    runner.registerInitialCondition("#{spaces_using_space_type.size} spaces are assigned to space type '#{space_type.name}'.")

    # get starting costs for spaces
    yr0_capital_totalCosts = -1 * get_total_costs_for_objects(spaces_using_space_type)

    # test that there is no sensor already in the space, and that zone object doesn't already have sensors assigned.
    spaces_using_space_type.each do |space_using_space_type|
      if space_using_space_type.daylightingControls.empty?
        space_zone = space_using_space_type.thermalZone
        if !space_zone.empty?
          space_zone = space_zone.get
          if space_zone.primaryDaylightingControl.empty? && space_zone.secondaryDaylightingControl.empty?
            spaces_using_space_type_in_zones_without_sensors << space_using_space_type
          elsif
            runner.registerWarning("Thermal zone '#{space_zone.name}' which includes space '#{space_using_space_type.name}' already had a daylighting sensor. No sensor was added to space '#{space_using_space_type.name}'.")
          end
        else
          runner.registerWarning("Space '#{space_using_space_type.name}' is not associated with a thermal zone. It won't be part of the EnergyPlus simulation.")
        end
      else
        runner.registerWarning("Space '#{space_using_space_type.name}' already has a daylighting sensor. No sensor was added.")
      end
    end

    # loop through all spaces,
    # and add a daylighting sensor with dimming to each
    space_count = 0
    spaces_using_space_type_in_zones_without_sensors.each do |space|
      space_count += 1
      area += space.floorArea

      # eliminate spaces that don't have exterior natural lighting
      has_ext_nat_light = false
      space.surfaces.each do |surface|
        next if surface.outsideBoundaryCondition != 'Outdoors'
        surface.subSurfaces.each do |sub_surface|
          next if sub_surface.subSurfaceType == 'Door'
          next if sub_surface.subSurfaceType == 'OverheadDoor'
          has_ext_nat_light = true
        end
      end
      if has_ext_nat_light == false
        runner.registerWarning("Space '#{space.name}' has no exterior natural lighting. No sensor will be added.")
        next
      end

      # find floors
      floors = []
      space.surfaces.each do |surface|
        next if surface.surfaceType != 'Floor'
        floors << surface
      end

      # this method only works for flat (non-inclined) floors
      boundingBox = OpenStudio::BoundingBox.new
      floors.each do |floor|
        boundingBox.addPoints(floor.vertices)
      end
      xmin = boundingBox.minX.get
      ymin = boundingBox.minY.get
      zmin = boundingBox.minZ.get
      xmax = boundingBox.maxX.get
      ymax = boundingBox.maxY.get

      # create a new sensor and put at the center of the space
      sensor = OpenStudio::Model::DaylightingControl.new(model)
      sensor.setName("#{space.name} daylighting control")
      x_pos = (xmin + xmax) / 2
      y_pos = (ymin + ymax) / 2
      z_pos = zmin + height_si # put it 1 meter above the floor
      new_point = OpenStudio::Point3d.new(x_pos, y_pos, z_pos)
      sensor.setPosition(new_point)
      sensor.setIlluminanceSetpoint(setpoint_si)
      sensor.setLightingControlType(control_type)
      sensor.setMinimumInputPowerFractionforContinuousDimmingControl(min_power_fraction)
      sensor.setMinimumLightOutputFractionforContinuousDimmingControl(min_light_fraction)
      sensor.setSpace(space)
      puts sensor

      # add lifeCycleCost objects if there is a non-zero value in one of the cost arguments
      if costs_requested == true

        starting_lcc_counter = space.lifeCycleCosts.size

        # adding new cost items
        lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{sensor.name}", space, material_cost, 'CostPerEach', 'Construction', expected_life, years_until_costs_start)
        if demo_cost_initial_const
          lcc_demo = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Demo - #{sensor.name}", space, demolition_cost, 'CostPerEach', 'Salvage', expected_life, years_until_costs_start)
        else
          lcc_demo = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Demo - #{sensor.name}", space, demolition_cost, 'CostPerEach', 'Salvage', expected_life, years_until_costs_start + expected_life)
        end
        lcc_om = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_OM - #{sensor.name}", space, om_cost, 'CostPerEach', 'Maintenance', om_frequency, 0)

        if space.lifeCycleCosts.size - starting_lcc_counter == 3
          if !warning_cost_assign_to_space
            runner.registerInfo('Cost for daylight sensors was added to spaces. The cost will remain in the model unless the space is removed. Removing only the sensor will not remove the cost.')
            warning_cost_assign_to_space = true
          end
        else
          runner.registerWarning("The measure did not function as expected. #{space.lifeCycleCosts.size - starting_lcc_counter} LifeCycleCost objects were made, 3 were expected.")
        end

      end

      # push unique zones to array for use later in measure
      temp_zone = space.thermalZone.get
      if affected_zone_names.include?(temp_zone.name.to_s) == false
        affected_zones << temp_zone
        affected_zone_names << temp_zone.name.to_s
      end

      # push sensor object into hash with space name
      new_sensor_objects[space.name.to_s] = sensor

      # add floor area to the daylighting area tally
      sensor_area += space.floorArea

      # add to sensor count for reporting
      sensor_count += 1
    end

    if (sensor_count == 0) && (costs_requested == false)
      runner.registerAsNotApplicable("No spaces that currently don't have sensor required a new sensor, and no lifecycle costs objects were requested.")
      return true
    end

    # loop through thermal Zones for spaces with daylighting controls added
    affected_zones.each do |zone|
      zone_spaces = zone.spaces
      zone_spaces_with_new_sensors = []
      zone_spaces.each do |zone_space|
        if !zone_space.daylightingControls.empty? && (zone_space.spaceType.get == space_type)
          zone_spaces_with_new_sensors << zone_space
        end
      end

      if !zone_spaces_with_new_sensors.empty?
        # need to identify the two largest spaces
        primary_area = 0
        secondary_area = 0
        primary_space = nil
        secondary_space = nil
        three_or_more_sensors = false

        # dfg temp - need to add another if statement so only get spaces with sensors
        zone_spaces_with_new_sensors.each do |zone_space|
          zone_space_area = zone_space.floorArea
          if zone_space_area > primary_area
            primary_area = zone_space_area
            primary_space = zone_space
          elsif zone_space_area > secondary_area
            secondary_area = zone_space_area
            secondary_space = zone_space
          else
            # setup flag to warn user that more than 2 sensors can't be added to a space
            three_or_more_sensors = true
          end
        end

        if primary_space
          # setup primary sensor
          sensor_primary = new_sensor_objects[primary_space.name.to_s]
          zone.setPrimaryDaylightingControl(sensor_primary)
          zone.setFractionofZoneControlledbyPrimaryDaylightingControl(fraction_zone_controlled * primary_area / (primary_area + secondary_area))
        end

        if secondary_space
          # setup secondary sensor
          sensor_secondary = new_sensor_objects[secondary_space.name.to_s]
          zone.setSecondaryDaylightingControl(sensor_secondary)
          zone.setFractionofZoneControlledbySecondaryDaylightingControl(fraction_zone_controlled * secondary_area / (primary_area + secondary_area))
        end

        # warn that additional sensors were not used
        if three_or_more_sensors == true
          runner.registerWarning("Thermal zone '#{zone.name}' had more than two spaces with sensors. Only two sensors were associated with the thermal zone.")
        end

      end
    end

    # setup OpenStudio units that we will need
    unit_area_ip = OpenStudio.createUnit('ft^2').get
    unit_area_si = OpenStudio.createUnit('m^2').get

    # define starting units
    area_si = OpenStudio::Quantity.new(sensor_area, unit_area_si)

    # unit conversion from IP units to SI units
    area_ip = OpenStudio.convert(area_si, unit_area_ip).get

    # get final costs for spaces
    yr0_capital_totalCosts = get_total_costs_for_objects(spaces_using_space_type)

    # reporting final condition of model
    runner.registerFinalCondition("Added daylighting controls to #{sensor_count} spaces, covering #{area_ip}. Initial year costs associated with the daylighting controls is $#{neat_numbers(yr0_capital_totalCosts, 0)}.")

    return true
  end
end

# this allows the measure to be used by the application
AddDaylightSensors.new.registerWithApplication
