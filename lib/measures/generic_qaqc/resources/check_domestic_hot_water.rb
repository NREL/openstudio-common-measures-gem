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

module OsLib_QAQC
  # include any general notes about QAQC method here

  # checks the number of unmet hours in the model
  def check_domestic_hot_water(category, target_standard, min_pass, max_pass, name_only = false)
    # TODO: - could expose meal turnover and people per unit for res and hotel into arguments

    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Domestic Hot Water')
    check_elems << OpenStudio::Attribute.new('category', category)
    if target_standard == 'ICC IECC 2015'
      check_elems << OpenStudio::Attribute.new('description', 'Check service water heating consumption against Table R405.5.2(1) in ICC IECC 2015 Residential Provisions.')
    else
      check_elems << OpenStudio::Attribute.new('description', 'Check against the 2011 ASHRAE Handbook - HVAC Applications, Table 7 section 50.14.')
    end

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      results = []
      check_elems.each do |elem|
        results << elem.valueAsString
      end
      return results
    end

    # Versions of OpenStudio greater than 2.4.0 use a modified version of
    # openstudio-standards with different method calls.  These methods
    # require a "Standard" object instead of the standard being passed into method calls.
    # This Standard object is used throughout the QAQC check.
    if OpenStudio::VersionString.new(OpenStudio.openStudioVersion) < OpenStudio::VersionString.new('2.4.3')
      use_old_gem_code = true
    else
      use_old_gem_code = false
      std = Standard.build(target_standard)
    end

    begin
      # loop through water_use_equipment
      service_water_consumption_daily_avg_gal = 0.0
      @model.getWaterUseEquipments.each do |water_use_equipment|
        # get peak flow rate from def
        peak_flow_rate_si = water_use_equipment.waterUseEquipmentDefinition.peakFlowRate
        source_units = 'm^3/s'
        target_units = 'gal/min'
        peak_flow_rate_ip = OpenStudio.convert(peak_flow_rate_si, source_units, target_units).get

        # get value from flow rate schedule
        if water_use_equipment.flowRateFractionSchedule.is_initialized
          # get annual equiv for model schedule
          schedule_inst = water_use_equipment.flowRateFractionSchedule.get
          if schedule_inst.to_ScheduleRuleset.is_initialized
            if use_old_gem_code
              annual_equiv_flow_rate = schedule_inst.to_ScheduleRuleset.get.annual_equivalent_full_load_hrs
            else
              annual_equiv_flow_rate = std.schedule_ruleset_annual_equivalent_full_load_hrs(schedule_inst.to_ScheduleRuleset.get)
            end
          elsif schedule_inst.to_ScheduleConstant.is_initialized
            if use_old_gem_code
              annual_equiv_flow_rate = schedule_inst.to_ScheduleConstant.get.annual_equivalent_full_load_hrs
            else
              annual_equiv_flow_rate = std.schedule_constant_annual_equivalent_full_load_hrs(schedule_inst.to_ScheduleConstant.get)
            end
          else
            check_elems << OpenStudio::Attribute.new('flag', "#{schedule_inst.name} isn't a Ruleset or Constant schedule. Can't calculate annual equivalent full load hours.")
            next
          end
        else
          # issue flag
          check_elems << OpenStudio::Attribute.new('flag', "#{water_use_equipment.name} doesn't have a schedule. Can't identify hot water consumption.")
          next
        end

        # add to global service water consumpiton value
        service_water_consumption_daily_avg_gal += 60.0 * peak_flow_rate_ip * annual_equiv_flow_rate / 365.0
      end

      if target_standard == 'ICC IECC 2015'

        num_people = 0.0
        @model.getSpaceTypes.each do |space_type|
          next if !space_type.standardsSpaceType.is_initialized
          next if space_type.standardsSpaceType.get != 'Apartment' # currently only supports midrise apt space type
          space_type_floor_area = space_type.floorArea
          space_type_num_people = space_type.getNumberOfPeople(space_type_floor_area)
          num_people += space_type_num_people
        end

        # lookup target gal/day for the building
        bedrooms_per_unit = 2.0 # assumption
        num_units = num_people / 2.5 # Avg 2.5 units per person.
        if use_old_gem_code
          target_consumption = @model.find_icc_iecc_2015_hot_water_demand(num_units, bedrooms_per_unit)
        else
          target_consumption = std.model_find_icc_iecc_2015_hot_water_demand(@model, num_units, bedrooms_per_unit)
        end

      else # only other path for now is 90.1-2013

        # get building type
        building_type = ''
        if @model.getBuilding.standardsBuildingType.is_initialized
          building_type = @model.getBuilding.standardsBuildingType.get
        end

        # lookup data from standards
        if use_old_gem_code
          ashrae_hot_water_demand = @model.find_ashrae_hot_water_demand
        else
          ashrae_hot_water_demand = std.model_find_ashrae_hot_water_demand(@model)
        end

        # building type specific logic for water consumption
        # todo - update test to exercise various building types
        if !ashrae_hot_water_demand.empty?

          if building_type == 'FullServiceRestaurant'
            num_people_hours = 0.0
            @model.getSpaceTypes.each do |space_type|
              next if !space_type.standardsSpaceType.is_initialized
              next if space_type.standardsSpaceType.get != 'Dining'
              space_type_floor_area = space_type.floorArea

              space_type_num_people_hours = 0.0
              # loop through peole instances
              space_type.peoples.each do |inst|
                inst_num_people = inst.getNumberOfPeople(space_type_floor_area)
                inst_schedule = inst.numberofPeopleSchedule.get # sim will fail prior to this if doesn't have it

                if inst_schedule.to_ScheduleRuleset.is_initialized
                  if use_old_gem_code
                    annual_equiv_flow_rate = inst_schedule.to_ScheduleRuleset.get.annual_equivalent_full_load_hrs
                  else
                    annual_equiv_flow_rate = std.schedule_ruleset_annual_equivalent_full_load_hrs(inst_schedule.to_ScheduleRuleset.get)
                  end
                elsif inst_schedule.to_ScheduleConstant.is_initialized
                  if use_old_gem_code
                    annual_equiv_flow_rate = inst_schedule.to_ScheduleConstant.get.annual_equivalent_full_load_hrs
                  else
                    annual_equiv_flow_rate = std.schedule_constant_annual_equivalent_full_load_hrs(inst_schedule.to_ScheduleConstant.get)
                  end
                else
                  check_elems << OpenStudio::Attribute.new('flag', "#{inst_schedule.name} isn't a Ruleset or Constant schedule. Can't calculate annual equivalent full load hours.")
                  annual_equiv_flow_rate = 0.0
                end

                inst_num_people_horus = annual_equiv_flow_rate * inst_num_people
                space_type_num_people_hours += inst_num_people_horus
              end

              num_people_hours += space_type_num_people_hours
            end
            num_meals = num_people_hours / 365.0 * 1.5 # 90 minute meal
            target_consumption = num_meals * ashrae_hot_water_demand.first[:avg_day_unit]

          elsif ['LargeHotel', 'SmallHotel'].include? building_type
            num_people = 0.0
            @model.getSpaceTypes.each do |space_type|
              next if !space_type.standardsSpaceType.is_initialized
              next if space_type.standardsSpaceType.get != 'GuestRoom'
              space_type_floor_area = space_type.floorArea
              space_type_num_people = space_type.getNumberOfPeople(space_type_floor_area)
              num_people += space_type_num_people
            end

            # find best fit from returned results
            num_units = num_people / 2.0 # 2 people per room design load, not typical occupancy
            avg_day_unit = nil
            fit = nil
            ashrae_hot_water_demand.each do |block|
              if fit.nil?
                avg_day_unit = block[:avg_day_unit]
                fit = (avg_day_unit - block[:block]).abs
              elsif (avg_day_unit - block[:block]).abs - fit
                avg_day_unit = block[:avg_day_unit]
                fit = (avg_day_unit - block[:block]).abs
              end
            end
            target_consumption = num_units * avg_day_unit

          elsif building_type == 'MidriseApartment'
            num_people = 0.0
            @model.getSpaceTypes.each do |space_type|
              next if !space_type.standardsSpaceType.is_initialized
              next if space_type.standardsSpaceType.get != 'Apartment'
              space_type_floor_area = space_type.floorArea
              space_type_num_people = space_type.getNumberOfPeople(space_type_floor_area)
              num_people += space_type_num_people
            end

            # find best fit from returned results
            num_units = num_people / 2.5 # Avg 2.5 units per person.
            avg_day_unit = nil
            fit = nil
            ashrae_hot_water_demand.each do |block|
              if fit.nil?
                avg_day_unit = block[:avg_day_unit]
                fit = (avg_day_unit - block[:block]).abs
              elsif (avg_day_unit - block[:block]).abs - fit
                avg_day_unit = block[:avg_day_unit]
                fit = (avg_day_unit - block[:block]).abs
              end
            end
            target_consumption = num_units * avg_day_unit

          elsif ['Office', 'LargeOffice', 'MediumOffice', 'SmallOffice'].include? building_type
            num_people = @model.getBuilding.numberOfPeople
            target_consumption = num_people * ashrae_hot_water_demand.first[:avg_day_unit]
          elsif building_type == 'PrimarySchool'
            num_people = 0.0
            @model.getSpaceTypes.each do |space_type|
              next if !space_type.standardsSpaceType.is_initialized
              next if space_type.standardsSpaceType.get != 'Classroom'
              space_type_floor_area = space_type.floorArea
              space_type_num_people = space_type.getNumberOfPeople(space_type_floor_area)
              num_people += space_type_num_people
            end
            target_consumption = num_people * ashrae_hot_water_demand.first[:avg_day_unit]
          elsif building_type == 'QuickServiceRestaurant'
            num_people_hours = 0.0
            @model.getSpaceTypes.each do |space_type|
              next if !space_type.standardsSpaceType.is_initialized
              next if space_type.standardsSpaceType.get != 'Dining'
              space_type_floor_area = space_type.floorArea

              space_type_num_people_hours = 0.0
              # loop through peole instances
              space_type.peoples.each do |inst|
                inst_num_people = inst.getNumberOfPeople(space_type_floor_area)
                inst_schedule = inst.numberofPeopleSchedule.get # sim will fail prior to this if doesn't have it

                if inst_schedule.to_ScheduleRuleset.is_initialized
                  if use_old_gem_code
                    annual_equiv_flow_rate = inst_schedule.to_ScheduleRuleset.get.annual_equivalent_full_load_hrs
                  else
                    annual_equiv_flow_rate = std.schedule_ruleset_annual_equivalent_full_load_hrs(inst_schedule.to_ScheduleRuleset.get)
                  end
                elsif inst_schedule.to_ScheduleConstant.is_initialized
                  if use_old_gem_code
                    annual_equiv_flow_rate = inst_schedule.to_ScheduleConstant.get.annual_equivalent_full_load_hrs
                  else
                    annual_equiv_flow_rate = std.schedule_constant_annual_equivalent_full_load_hrs(inst_schedule.to_ScheduleConstant.get)
                  end
                else
                  check_elems << OpenStudio::Attribute.new('flag', "#{inst_schedule.name} isn't a Ruleset or Constant schedule. Can't calculate annual equivalent full load hours.")
                  annual_equiv_flow_rate = 0.0
                end

                inst_num_people_horus = annual_equiv_flow_rate * inst_num_people
                space_type_num_people_hours += inst_num_people_horus
              end

              num_people_hours += space_type_num_people_hours
            end
            num_meals = num_people_hours / 365.0 * 0.5 # 30 minute leal
            # todo - add logic to address drive through traffic
            target_consumption = num_meals * ashrae_hot_water_demand.first[:avg_day_unit]

          elsif building_type == 'SecondarySchool'
            num_people = 0.0
            @model.getSpaceTypes.each do |space_type|
              next if !space_type.standardsSpaceType.is_initialized
              next if space_type.standardsSpaceType.get != 'Classroom'
              space_type_floor_area = space_type.floorArea
              space_type_num_people = space_type.getNumberOfPeople(space_type_floor_area)
              num_people += space_type_num_people
            end
            target_consumption = num_people * ashrae_hot_water_demand.first[:avg_day_unit]
          else
            check_elems << OpenStudio::Attribute.new('flag', "No rule of thumb values exist for  #{building_type}. Hot water consumption was not checked.")
          end

        else
          check_elems << OpenStudio::Attribute.new('flag', "No rule of thumb values exist for  #{building_type}. Hot water consumption was not checked.")
        end

      end

      # check actual against target
      if service_water_consumption_daily_avg_gal < target_consumption * (1.0 - min_pass)
        check_elems <<  OpenStudio::Attribute.new('flag', "Annual average of #{service_water_consumption_daily_avg_gal.round} gallons per day of hot water is more than #{min_pass * 100} % below the expected value of #{target_consumption.round} gallons per day.")
      elsif service_water_consumption_daily_avg_gal > target_consumption * (1.0 + max_pass)
        check_elems <<  OpenStudio::Attribute.new('flag', "Annual average of #{service_water_consumption_daily_avg_gal.round} gallons per day of hot water is more than #{max_pass * 100} % above the expected value of #{target_consumption.round} gallons per day.")
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
end
