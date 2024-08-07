# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

module OsLib_QAQC
  # include any general notes about QAQC method here

  # checks the number of unmet hours in the model
  def check_schedules(category, target_standard, min_pass, max_pass, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Schedules')
    check_elems << OpenStudio::Attribute.new('category', category)

    # update display sttandard
    if target_standard.include?('90.1')
      display_standard = "ASHRAE #{target_standard}"
    else
      display_standard = target_standard
    end

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      results = []
      check_elems << OpenStudio::Attribute.new('description', 'Check schedules for lighting, ventilation, occupant density, plug loads, and equipment based on DOE reference building schedules in terms of full load hours per year.')
      check_elems.each do |elem|
        results << elem.valueAsString
      end
      return results
    end

    begin

      # setup standard
      std = Standard.build(target_standard)

      # gather building type for summary
      if Gem::Version.new(OpenstudioStandards::VERSION) > Gem::Version.new('0.2.16')
        bt_cz = std.model_get_building_properties(@model)
      else
        bt_cz = std.model_get_building_climate_zone_and_building_type(@model)
      end

      building_type = bt_cz['building_type']
      # mapping to obuilding type to match space types
      if building_type.include?("Office") then building_type = "Office" end
      climate_zone = bt_cz['climate_zone']
      prototype_prefix = "#{display_standard} #{building_type} #{climate_zone}"
      check_elems << OpenStudio::Attribute.new('description', "Check schedules for lighting, ventilation, occupant density, plug loads, and equipment based on #{prototype_prefix} DOE reference building schedules in terms of full load hours per year.")
      check_elems << OpenStudio::Attribute.new('min_pass', min_pass * 100)
      check_elems << OpenStudio::Attribute.new('max_pass', max_pass * 100)

      # gather all non statandard space types so can be listed in single flag
      non_tagged_space_types = []

      # loop through all space types used in the model
      @model.getSpaceTypes.each do |space_type|
        next if space_type.floorArea <= 0

        # load in standard info for this space type
        data = std.space_type_get_standards_data(space_type)

        if data.nil? || data.empty?

          # skip if all spaces using this space type are plenums
          all_spaces_plenums = true
          space_type.spaces.each do |space|
            if !OpenstudioStandards::Space.space_plenum?(space)
              all_spaces_plenums = false
              next
            end
          end

          if !all_spaces_plenums
            non_tagged_space_types << space_type.floorArea
          end

          next
        end

        # temp model to hold schedules to check
        model_temp = OpenStudio::Model::Model.new

        # check lighting schedules
        data['lighting_per_area'].nil? ? (target_ip = 0.0) : (target_ip = data['lighting_per_area'])
        if target_ip.to_f > 0
          schedule_target = std.model_add_schedule(model_temp, data['lighting_schedule'])
          if !schedule_target
            check_elems << OpenStudio::Attribute.new('flag', "Didn't find schedule named #{data['lighting_schedule']} in standards json.")
          else
            # loop through and test individual load instances
            target_hrs = OpenstudioStandards::Schedules.schedule_ruleset_get_equivalent_full_load_hours(schedule_target.to_ScheduleRuleset.get)
            space_type.lights.each do |load_inst|
              inst_sch_check = generate_load_insc_sch_check_attribute(target_hrs, load_inst, space_type, check_elems, min_pass, max_pass, target_standard)
              if inst_sch_check then check_elems << inst_sch_check end
            end

          end
        end

        # check electric equipment schedules
        data['electric_equipment_per_area'].nil? ? (target_ip = 0.0) : (target_ip = data['electric_equipment_per_area'])
        if target_ip.to_f > 0
          schedule_target = std.model_add_schedule(model_temp, data['electric_equipment_schedule'])
          if !schedule_target
            check_elems << OpenStudio::Attribute.new('flag', "Didn't find schedule named #{data['electric_equipment_schedule']} in standards json.")
          else
            # loop through and test individual load instances
            target_hrs = OpenstudioStandards::Schedules.schedule_ruleset_get_equivalent_full_load_hours(schedule_target.to_ScheduleRuleset.get)

            space_type.electricEquipment.each do |load_inst|
              inst_sch_check = generate_load_insc_sch_check_attribute(target_hrs, load_inst, space_type, check_elems, min_pass, max_pass, target_standard)
              if inst_sch_check then check_elems << inst_sch_check end
            end
          end
        end

        # check gas equipment schedules
        # todo - update measure test to with space type to check this
        data['gas_equipment_per_area'].nil? ? (target_ip = 0.0) : (target_ip = data['gas_equipment_per_area'])
        if target_ip.to_f > 0
          schedule_target = std.model_add_schedule(model_temp, data['gas_equipment_schedule'])
          if !schedule_target
            check_elems << OpenStudio::Attribute.new('flag', "Didn't find schedule named #{data['gas_equipment_schedule']} in standards json.")
          else
            # loop through and test individual load instances
            target_hrs = OpenstudioStandards::Schedules.schedule_ruleset_get_equivalent_full_load_hours(schedule_target.to_ScheduleRuleset.get)
            space_type.gasEquipment.each do |load_inst|
              inst_sch_check = generate_load_insc_sch_check_attribute(target_hrs, load_inst, space_type, check_elems, min_pass, max_pass, target_standard)
              if inst_sch_check then check_elems << inst_sch_check end
            end
          end
        end

        # check occupancy schedules
        data['occupancy_per_area'].nil? ? (target_ip = 0.0) : (target_ip = data['occupancy_per_area'])
        if target_ip.to_f > 0
          schedule_target = std.model_add_schedule(model_temp, data['occupancy_schedule'])
          if !schedule_target
            check_elems << OpenStudio::Attribute.new('flag', "Didn't find schedule named #{data['occupancy_schedule']} in standards json.")
          else
            # loop through and test individual load instances
            target_hrs = OpenstudioStandards::Schedules.schedule_ruleset_get_equivalent_full_load_hours(schedule_target.to_ScheduleRuleset.get)
            space_type.people.each do |load_inst|
              inst_sch_check = generate_load_insc_sch_check_attribute(target_hrs, load_inst, space_type, check_elems, min_pass, max_pass, target_standard)
              if inst_sch_check then check_elems << inst_sch_check end
            end

          end
        end

        # TODO: - check ventilation schedules
        # if objects are in the model should they just be always on schedule, or have a 8760 annual equiv value
        # oa_schedule should not exist, or if it does shoudl be always on or have 8760 annual equiv value
        if space_type.designSpecificationOutdoorAir.is_initialized
          oa = space_type.designSpecificationOutdoorAir.get
          if oa.outdoorAirFlowRateFractionSchedule.is_initialized
            # TODO: - update measure test to check this
            target_hrs = 8760
            inst_sch_check = generate_load_insc_sch_check_attribute(target_hrs, oa, space_type, check_elems, min_pass, max_pass, target_standard)
            if inst_sch_check then check_elems << inst_sch_check end
          end
        end

        # notes
        # current logic only looks at 8760 values and not design days
        # when multiple instances of a type currently check every schedule by itself. In future could do weighted avg. merge
        # not looking at infiltration schedules
        # not looking at luminaires
        # not looking at space loads, only loads at space type
        # only checking schedules where standard shows non zero load value
        # model load for space type where standards doesn't have one wont throw flag about mis-matched schedules
      end

      # report about non standard space types
      if non_tagged_space_types.size > 0
        impacted_floor_area = non_tagged_space_types.sum
        building_area = @model.getBuilding.floorArea
        check_elems << OpenStudio::Attribute.new('flag', "Unexpected standard building/space types found for #{non_tagged_space_types.size} space types covering #{(100 * impacted_floor_area/building_area).round}% of floor area, can't provide comparisons for schedules for those space types.")
      end

      # warn if there are spaces in model that don't use space type unless they appear to be plenums
      @model.getSpaces.each do |space|
        next if OpenstudioStandards::Space.space_plenum?(space)
        if !space.spaceType.is_initialized
          check_elems << OpenStudio::Attribute.new('flag', "#{space.name} doesn't have a space type assigned, can't validate schedules.")
        end
      end
    rescue StandardError => e
      # brief description of ruby error
      check_elems << OpenStudio::Attribute.new('flag', "Error prevented QAQC check from running (#{e}).")

      # backtrace of ruby error for diagnostic use
      if @error_backtrace then check_elems << OpenStudio::Attribute.new('flag', e.backtrace.join("\n").to_s) end
    end

    # add check_elms to new attribute
    check_elem = OpenStudio::Attribute.new('check', check_elems)

    return check_elem
    # note: registerWarning and registerValue will be added for checks downstream using os_lib_reporting_qaqc.rb
  end

  # code for each load instance for different load types will pass through here
  # will return nill or a single attribute
  def generate_load_insc_sch_check_attribute(target_hrs, load_inst, space_type, check_elems, min_pass, max_pass, target_standard)
    schedule_inst = nil
    inst_hrs = nil

    # setup standard
    std = Standard.build(target_standard)

    # gather building type for summary
    if Gem::Version.new(OpenstudioStandards::VERSION) > Gem::Version.new('0.2.16')
      bt_cz = std.model_get_building_properties(@model)
    else
      bt_cz = std.model_get_building_climate_zone_and_building_type(@model)
    end
    building_type = bt_cz['building_type']
    climate_zone = bt_cz['climate_zone']
    prototype_prefix = "#{target_standard} #{building_type} #{climate_zone}"

    # get schedule
    if (load_inst.class.to_s == 'OpenStudio::Model::People') && load_inst.numberofPeopleSchedule.is_initialized
      schedule_inst = load_inst.numberofPeopleSchedule.get
    elsif (load_inst.class.to_s == 'OpenStudio::Model::DesignSpecificationOutdoorAir') && load_inst.outdoorAirFlowRateFractionSchedule.is_initialized
      schedule_inst = load_inst.outdoorAirFlowRateFractionSchedule .get
    elsif load_inst.schedule.is_initialized
      schedule_inst = load_inst.schedule.get
    else
      return OpenStudio::Attribute.new('flag', "#{load_inst.name} in #{space_type.name} doesn't have a schedule assigned.")
    end

    # get annual equiv for model schedule
    if schedule_inst.to_ScheduleRuleset.is_initialized
      inst_hrs = OpenstudioStandards::Schedules.schedule_ruleset_get_equivalent_full_load_hours(schedule_inst.to_ScheduleRuleset.get)
    elsif schedule_inst.to_ScheduleConstant.is_initialized
      inst_hrs = std.schedule_constant_annual_equivalent_full_load_hrs(schedule_inst.to_ScheduleConstant.get)
    else
      return OpenStudio::Attribute.new('flag', "#{schedule_inst.name} isn't a Ruleset or Constant schedule. Can't calculate annual equivalent full load hours.")
    end

    # check instance against target
    if inst_hrs < target_hrs * (1.0 - min_pass)
      return OpenStudio::Attribute.new('flag', "#{inst_hrs.round} annual equivalent full load hours for #{schedule_inst.name} in #{space_type.name} is more than #{min_pass * 100} (%) below the value of #{target_hrs.round} hours from the #{prototype_prefix} DOE Prototype building.")
    elsif inst_hrs > target_hrs * (1.0 + max_pass)
      return OpenStudio::Attribute.new('flag', "#{inst_hrs.round} annual equivalent full load hours for #{schedule_inst.name} in #{space_type.name}  is more than #{max_pass * 100} (%) above the value of #{target_hrs.round} hours from the #{prototype_prefix} DOE Prototype building.")
    end

    # will get to this if no flag was thrown
    return false
  end
end
