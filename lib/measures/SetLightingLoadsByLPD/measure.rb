# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# start the measure
class SetLightingLoadsByLPD < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see
  def name
    return 'Set Lighting Loads by LPD'
  end

  # human readable description
  def description
    return 'Set the lighting power density (W/ft^2) in the to a specified value for all spaces that have lights. This can be applied to the entire building or a specific space type. Cost can be added per floor area'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Delete all of the existing lighting in the model. Add lights with the user defined lighting power density to all spaces that initially had lights, using the schedule from the original lights. If multiple lights existed the schedule will be pulled from the one with the highest lighting power density value. Demolition costs from lights and luminaires removed by this measure can be included in the analysis.'
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

    # add building to string vector with space type
    building = model.getBuilding
    space_type_handles << building.handle.to_s
    space_type_display_names << '*Entire Building*'

    # make a choice argument for space type or entire building
    space_type = OpenStudio::Measure::OSArgument.makeChoiceArgument('space_type', space_type_handles, space_type_display_names, true)
    space_type.setDisplayName('Apply the Measure to a Specific Space Type or to the Entire Model')
    space_type.setDefaultValue('*Entire Building*') # if no space type is chosen this will run on the entire building
    args << space_type

    # make an argument LPD
    lpd = OpenStudio::Measure::OSArgument.makeDoubleArgument('lpd', true)
    lpd.setDisplayName('Lighting Power Density (W/ft^2)')
    lpd.setDefaultValue(1.0)
    args << lpd

    # add in argument to add lights to all spaces that are included in building floor area even if original space didn't have lights
    add_instance_all_spaces = OpenStudio::Measure::OSArgument.makeBoolArgument('add_instance_all_spaces', true)
    add_instance_all_spaces.setDisplayName('Add lights to all spaces included in floor area, including spaces that did not originally include lights')
    add_instance_all_spaces.setDefaultValue(false)
    args << add_instance_all_spaces

    # make an argument for material and installation cost
    material_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('material_cost', true)
    material_cost.setDisplayName('Material and Installation Costs for Lights per Floor Area ($/ft^2).')
    material_cost.setDefaultValue(0.0)
    args << material_cost

    # make an argument for demolition cost
    demolition_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('demolition_cost', true)
    demolition_cost.setDisplayName('Demolition Costs for Lights per Floor Area ($/ft^2).')
    demolition_cost.setDefaultValue(0.0)
    args << demolition_cost

    # make an argument for duration in years until costs start
    years_until_costs_start = OpenStudio::Measure::OSArgument.makeIntegerArgument('years_until_costs_start', true)
    years_until_costs_start.setDisplayName('Years Until Costs Start (whole years).')
    years_until_costs_start.setDefaultValue(0)
    args << years_until_costs_start

    # make an argument to determine if demolition costs should be included in initial construction
    demo_cost_initial_const = OpenStudio::Measure::OSArgument.makeBoolArgument('demo_cost_initial_const', true)
    demo_cost_initial_const.setDisplayName('Demolition Costs Occur During Initial Construction?')
    demo_cost_initial_const.setDefaultValue(false)
    args << demo_cost_initial_const

    # make an argument for expected life
    expected_life = OpenStudio::Measure::OSArgument.makeIntegerArgument('expected_life', true)
    expected_life.setDisplayName('Expected Life (whole years).')
    expected_life.setDefaultValue(20)
    args << expected_life

    # make an argument for o&m cost
    om_cost = OpenStudio::Measure::OSArgument.makeDoubleArgument('om_cost', true)
    om_cost.setDisplayName('O & M Costs for Lights per Floor Area ($/ft^2).')
    om_cost.setDefaultValue(0.0)
    args << om_cost

    # make an argument for o&m frequency
    om_frequency = OpenStudio::Measure::OSArgument.makeIntegerArgument('om_frequency', true)
    om_frequency.setDisplayName('O & M Frequency (whole years).')
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
    object = runner.getOptionalWorkspaceObjectChoiceValue('space_type', user_arguments, model)
    lpd = runner.getDoubleArgumentValue('lpd', user_arguments)
    add_instance_all_spaces = runner.getBoolArgumentValue('add_instance_all_spaces', user_arguments)
    material_cost = runner.getDoubleArgumentValue('material_cost', user_arguments)
    demolition_cost = runner.getDoubleArgumentValue('demolition_cost', user_arguments)
    years_until_costs_start = runner.getIntegerArgumentValue('years_until_costs_start', user_arguments)
    demo_cost_initial_const = runner.getBoolArgumentValue('demo_cost_initial_const', user_arguments)
    expected_life = runner.getIntegerArgumentValue('expected_life', user_arguments)
    om_cost = runner.getDoubleArgumentValue('om_cost', user_arguments)
    om_frequency = runner.getIntegerArgumentValue('om_frequency', user_arguments)

    # check the space_type for reasonableness and see if measure should run on space type or on the entire building
    apply_to_building = false
    space_type = nil
    if object.empty?
      handle = runner.getStringArgumentValue('space_type', user_arguments)
      if handle.empty?
        runner.registerError('No SpaceType was chosen.')
      else
        runner.registerError("The selected space type with handle '#{handle}' was not found in the model. It may have been removed by another measure.")
      end
      return false
    else
      if !object.get.to_SpaceType.empty?
        space_type = object.get.to_SpaceType.get
      elsif !object.get.to_Building.empty?
        apply_to_building = true
        # space_type = model.getSpaceTypes
      else
        runner.registerError('Script Error - argument not showing up as space type or building.')
        return false
      end
    end

    # check the lpd for reasonableness
    if (lpd < 0) || (lpd > 50)
      runner.registerError("A Lighting Power Density of #{lpd} W/ft^2 is above the measure limit.")
      return false
    elsif lpd > 21
      runner.registerWarning("A Lighting Power Density of #{lpd} W/ft^2 is abnormally high.")
    end

    # set flags to use later
    costs_requested = false

    # check costs for reasonableness
    if material_cost.abs + demolition_cost.abs + om_cost.abs == 0
      runner.registerInfo('No costs were requested for Exterior Lights.')
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

    # helper to make it easier to do unit conversions on the fly.  The definition be called through this measure.
    def unit_helper(number, from_unit_string, to_unit_string)
      converted_number = OpenStudio.convert(OpenStudio::Quantity.new(number, OpenStudio.createUnit(from_unit_string).get), OpenStudio.createUnit(to_unit_string).get).get.value
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

    # helper def to add to demo cost related to baseline objects
    def add_to_baseline_demo_cost_counter(baseline_object) # removed if statement from def
      counter = 0
      baseline_object_LCCs = baseline_object.lifeCycleCosts
      baseline_object_LCCs.each do |baseline_object_LCC|
        if baseline_object_LCC.category == 'Salvage'
          counter += baseline_object_LCC.totalCost
        end
      end
      return counter
    end

    # setup OpenStudio units that we will need
    unit_lpd_ip = OpenStudio.createUnit('W/ft^2').get
    unit_lpd_si = OpenStudio.createUnit('W/m^2').get

    # define starting units
    lpd_ip = OpenStudio::Quantity.new(lpd, unit_lpd_ip)

    # unit conversion of lpd from IP units (W/ft^2) to SI units (W/m^2)
    lpd_si = OpenStudio.convert(lpd_ip, unit_lpd_si).get

    # calculate the initial lights and luminaires cost for initial condition
    light_defs = model.getLightsDefinitions
    luminaire_defs = model.getLuminaireDefinitions
    initial_lighting_cost = 0
    initial_lighting_cost += get_total_costs_for_objects(light_defs)
    initial_lighting_cost += get_total_costs_for_objects(luminaire_defs)

    # counter for demo cost of baseline objects
    demo_costs_of_baseline_objects = 0

    # get demo cost if all existing lights and luminaires are removed
    if demo_cost_initial_const
      light_defs.each do |light_def|
        demo_costs_of_baseline_objects += add_to_baseline_demo_cost_counter(light_def)
      end
      luminaire_defs.each do |luminaire_def|
        demo_costs_of_baseline_objects += add_to_baseline_demo_cost_counter(luminaire_def)
      end
    end

    # find most common lights schedule for use in spaces that do not have lights
    light_sch_hash = {}
    # add schedules or lights directly assigned to space
    model.getSpaces.each do |space|
      space.lights.each do |light|
        if light.schedule.is_initialized
          sch = light.schedule.get
          if light_sch_hash.key?(sch)
            light_sch_hash[sch] += 1
          else
            light_sch_hash[sch] = 1
          end
        end
      end
      # add schedule for lights assigned to space types
      if space.spaceType.is_initialized
        space.spaceType.get.lights.each do |light|
          if light.schedule.is_initialized
            sch = light.schedule.get
            if light_sch_hash.key?(sch)
              light_sch_hash[sch] += 1
            else
              light_sch_hash[sch] = 1
            end
          end
        end
      end
    end
    most_comm_sch = light_sch_hash.key(light_sch_hash.values.max)

    # report initial condition
    building = model.getBuilding
    building_start_lpd_si = OpenStudio::Quantity.new(building.lightingPowerPerFloorArea, unit_lpd_si)
    building_start_lpd_ip = OpenStudio.convert(building_start_lpd_si, unit_lpd_ip).get
    runner.registerInitialCondition("The model's initial LPD is #{building_start_lpd_ip}. Initial Year 0 cost for building lighting is $#{neat_numbers(initial_lighting_cost, 0)}.")

    # add if statement for NA if LPD = 0
    if building_start_lpd_ip.value <= 0
      runner.registerAsNotApplicable('The model has no lights, nothing will be changed.')
    end

    # create a new LightsDefinition and new Lights object to use with setLightingPowerPerFloorArea
    template_light_def = OpenStudio::Model::LightsDefinition.new(model)
    template_light_def.setName("LPD #{lpd_ip} - LightsDef")
    template_light_def.setWattsperSpaceFloorArea(lpd_si.value)

    template_light_inst = OpenStudio::Model::Lights.new(template_light_def)
    template_light_inst.setName("LPD #{lpd_ip} - LightsInstance")

    # add lifeCycleCost objects if there is a non-zero value in one of the cost arguments
    if costs_requested == true

      starting_lcc_counter = template_light_def.lifeCycleCosts.size

      # get si input values for lcc objects
      material_cost_si = unit_helper(material_cost, '1/ft^2', '1/m^2')
      demolition_cost_si = unit_helper(demolition_cost, '1/ft^2', '1/m^2')
      om_cost_si = unit_helper(om_cost, '1/ft^2', '1/m^2')

      # adding new cost items
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Mat - #{template_light_def.name}", template_light_def, material_cost_si, 'CostPerArea', 'Construction', expected_life, years_until_costs_start)
      lcc_demo = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_Demo - #{template_light_def.name}", template_light_def, demolition_cost_si, 'CostPerArea', 'Salvage', expected_life, years_until_costs_start + expected_life)
      lcc_om = OpenStudio::Model::LifeCycleCost.createLifeCycleCost("LCC_OM - #{template_light_def.name}", template_light_def, om_cost_si, 'CostPerArea', 'Maintenance', om_frequency, 0)

      if template_light_def.lifeCycleCosts.size - starting_lcc_counter != 3
        runner.registerWarning("The measure did not function as expected. #{template_light_def.lifeCycleCosts.size - starting_lcc_counter} LifeCycleCost objects were made, 3 were expected.")
      end

    end

    # show as not applicable if no cost requested
    if costs_requested == false
      runner.registerAsNotApplicable('No new lifecycle costs objects were requested.')
    end

    # get space types in model
    if apply_to_building
      space_types = model.getSpaceTypes
    else
      space_types = []
      space_types << space_type # only run on a single space type
    end

    # loop through space types
    space_types.each do |space_type|
      space_type_lights = space_type.lights
      space_type_spaces = space_type.spaces
      multiple_schedules = false

      space_type_lights_array = []

      # if space type has lights and is used in the model
      if !space_type_lights.empty? && !space_type_spaces.empty?
        lights_schedules = []
        space_type_lights.each do |space_type_light|
          lights_data_for_array = []
          if !space_type_light.schedule.empty?
            space_type_light_new_schedule = space_type_light.schedule
            if !space_type_light_new_schedule.empty?
              lights_schedules << space_type_light.powerPerFloorArea
              if !space_type_light.powerPerFloorArea.empty?
                lights_data_for_array << space_type_light.powerPerFloorArea.get
              else
                lights_data_for_array << 0.0
              end
              lights_data_for_array << space_type_light_new_schedule.get
              lights_data_for_array << space_type_light.isScheduleDefaulted
              space_type_lights_array << lights_data_for_array
            end
          end
        end

        # pick schedule to use and see if it is defaulted
        space_type_lights_array = space_type_lights_array.sort.reverse[0]
        if !space_type_lights_array.nil? # this is need if schedule is empty but also not defaulted
          if space_type_lights_array[2] != true # if not schedule defaulted
            preferred_schedule = space_type_lights_array[1]
          else
            # leave schedule blank, it is defaulted
          end
        end

        # flag if lights_schedules has more than one unique object
        if lights_schedules.uniq.size > 1
          multiple_schedules = true
        end

        # delete lights and luminaires and add in new light.
        space_type_lights = space_type.lights
        space_type_luminaires = space_type.luminaires
        space_type_lights.each(&:remove)
        space_type_luminaires.each(&:remove)
        space_type_light_new = template_light_inst.clone(model)
        space_type_light_new = space_type_light_new.to_Lights.get
        space_type_light_new.setSpaceType(space_type)

        # assign preferred schedule to new lights object
        if defined? space_type_lights_array
          if !space_type_light_new.schedule.empty? && (space_type_lights_array[2] != true)
            space_type_light_new.setSchedule(preferred_schedule)
          end
        else
          runner.registerWarning("Not adding schedule for light in #{space_type.name}, no original light to harvest schedule from.")
        end

        # if schedules had to be removed due to multiple lights add warning
        if !space_type_light_new.schedule.empty? && (multiple_schedules == true)
          space_type_light_new_schedule = space_type_light_new.schedule
          runner.registerWarning("The space type named '#{space_type.name}' had more than one light object with unique schedules. The schedule named '#{space_type_light_new_schedule.get.name}' was used for the new LPD light object.")
        end

      elsif space_type_lights.empty? && !space_type_spaces.empty?
        runner.registerInfo("The space type named '#{space_type.name}' doesn't have any lights, none will be added.")
      end
    end

    # getting spaces in the model
    spaces = model.getSpaces

    # get space types in model
    if apply_to_building
      spaces = model.getSpaces
    else
      if !space_type.spaces.empty?
        spaces = space_type.spaces # only run on a single space type
      end
    end

    spaces.each do |space|
      space_lights = space.lights
      space_luminaires = space.luminaires
      space_space_type = space.spaceType
      if !space_space_type.empty?
        space_space_type_lights = space_space_type.get.lights
      else
        space_space_type_lights = []
      end

      # array to manage light schedules within a space
      space_lights_array = []

      # if space has lights and space type also has lights
      if !space_lights.empty? && !space_space_type_lights.empty?

        # loop through and remove all lights and luminaires
        space_lights.each(&:remove)
        runner.registerWarning("The space named '#{space.name}' had one or more light objects. These were deleted and a new LPD light object was added to the parent space type named '#{space_space_type.get.name}'.")

        space_luminaires.each(&:remove)
        if !space_luminaires.empty?
          runner.registerWarning('Luminaire objects have been removed. Their schedules were not taken into consideration when choosing schedules for the new LPD light object.')
        end

      elsif !space_lights.empty? && space_space_type_lights.empty?

        # inspect schedules for light objects
        multiple_schedules = false
        lights_schedules = []
        space_lights.each do |space_light|
          lights_data_for_array = []
          if !space_light.schedule.empty?
            space_light_new_schedule = space_light.schedule
            if !space_light_new_schedule.empty?
              lights_schedules << space_light.powerPerFloorArea
              if !space_light.powerPerFloorArea.empty?
                lights_data_for_array << space_light.powerPerFloorArea.get
              else
                lights_data_for_array << 0.0
              end
              lights_data_for_array << space_light_new_schedule.get
              lights_data_for_array << space_light.isScheduleDefaulted
              space_lights_array << lights_data_for_array
            end
          end
        end

        # pick schedule to use and see if it is defaulted
        space_lights_array = space_lights_array.sort.reverse[0]
        if !space_lights_array.nil?
          if space_lights_array[2] != true
            preferred_schedule = space_lights_array[1]
          else
            # leave schedule blank, it is defaulted
          end
        end

        # flag if lights_schedules has more than one unique object
        if lights_schedules.uniq.size > 1
          multiple_schedules = true
        end

        # delete lights and luminaires and add in new light.
        space_lights.each(&:remove)
        space_luminaires.each(&:remove)
        space_light_new = template_light_inst.clone(model)
        space_light_new = space_light_new.to_Lights.get
        space_light_new.setSpace(space)

        # assign preferred schedule to new lights object
        if defined? space_type_lights_array
          if !space_light_new.schedule.empty? && (space_type_lights_array[2] != true)
            space_light_new.setSchedule(preferred_schedule)
          end
        else
          runner.registerWarning("Not adding schedule for light in #{space.name}, no original light to harvest schedule from.")
        end

        # if schedules had to be removed due to multiple lights add warning here
        if !space_light_new.schedule.empty? && (multiple_schedules == true)
          space_light_new_schedule = space_light_new.schedule
          runner.registerWarning("The space type named '#{space.name}' had more than one light object with unique schedules. The schedule named '#{space_light_new_schedule.get.name}' was used for the new LPD light object.")
        end

      elsif space_lights.empty? && space_space_type_lights.empty?

        # add in light for spaces that do not have any with most common schedule
        if add_instance_all_spaces && space.partofTotalFloorArea
          space_light_new = template_light_inst.clone(model)
          space_light_new = space_light_new.to_Lights.get
          space_light_new.setSpace(space)
          space_light_new.setSchedule(most_comm_sch)
          runner.registerInfo("Adding light to #{space.name} using #{most_comm_sch.name} as fractional schedule.")
        else
          # issue warning that the space does not have any direct or inherited lights.
          runner.registerInfo("The space named '#{space.name}' does not have any direct or inherited lights. No light was added")
        end

      end
    end

    # subtract demo cost of lights and luminaires that were not deleted so the demo costs are not counted
    if demo_cost_initial_const
      light_defs.each do |light_def| # this does not loop through the new def (which is the desired behavior)
        demo_costs_of_baseline_objects += -1 * add_to_baseline_demo_cost_counter(light_def)
        puts "#{light_def.name},#{add_to_baseline_demo_cost_counter(light_def)}"
      end
      luminaire_defs.each do |luminaire_def|
        demo_costs_of_baseline_objects += -1 * add_to_baseline_demo_cost_counter(luminaire_def)
      end
    end

    # clean up template light instance. Will EnergyPlus will fail if you have an instance that isn't associated with a space or space type
    template_light_inst.remove

    # calculate the final lights and cost for initial condition.
    light_defs = model.getLightsDefinitions # this is done again to get the new def made by the measure
    luminaire_defs = model.getLuminaireDefinitions
    final_lighting_cost = 0
    final_lighting_cost += get_total_costs_for_objects(light_defs)
    final_lighting_cost += get_total_costs_for_objects(luminaire_defs)

    # add one time demo cost of removed lights and luminaires if appropriate
    if demo_cost_initial_const == true
      building = model.getBuilding
      lcc_baseline_demo = OpenStudio::Model::LifeCycleCost.createLifeCycleCost('LCC_baseline_demo', building, demo_costs_of_baseline_objects, 'CostPerEach', 'Salvage', 0, years_until_costs_start).get # using 0 for repeat period since one time cost.
      runner.registerInfo("Adding one time cost of $#{neat_numbers(lcc_baseline_demo.totalCost, 0)} related to demolition of baseline objects.")

      # if demo occurs on year 0 then add to initial capital cost counter
      if lcc_baseline_demo.yearsFromStart == 0
        final_lighting_cost += lcc_baseline_demo.totalCost
      end
    end

    # report final condition
    building_final_lpd_si = OpenStudio::Quantity.new(building.lightingPowerPerFloorArea, unit_lpd_si)
    building_final_lpd_ip = OpenStudio.convert(building_final_lpd_si, unit_lpd_ip).get
    runner.registerFinalCondition("Your model's final LPD is #{building_final_lpd_ip}. Final Year 0 cost for building lighting is $#{neat_numbers(final_lighting_cost, 0)}.")

    return true
  end
end

# this allows the measure to be used by the application
SetLightingLoadsByLPD.new.registerWithApplication
