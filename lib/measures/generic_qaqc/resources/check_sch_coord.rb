# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

module OsLib_QAQC
  # Determine the hour when the schedule first exceeds the starting value and when
  # it goes back down to the ending value at the end of the day.
  # This method only works for ScheduleRuleset schedules.
  def get_start_and_end_times(schedule_ruleset)
    # Ensure that this is a ScheduleRuleset
    schedule_ruleset = schedule_ruleset.to_ScheduleRuleset
    return [nil, nil] if schedule_ruleset.empty?
    schedule_ruleset = schedule_ruleset.get

    # Define the start and end date
    year_start_date = nil
    year_end_date = nil
    if schedule_ruleset.model.yearDescription.is_initialized
      year_description = schedule_ruleset.model.yearDescription.get
      year = year_description.assumedYear
      year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1, year)
      year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('December'), 31, year)
    else
      year_start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('January'), 1, 2009)
      year_end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new('December'), 31, 2009)
    end

    # Get the ordered list of all the day schedules that are used by this schedule ruleset
    day_schs = schedule_ruleset.getDaySchedules(year_start_date, year_end_date)

    # Get a 365-value array of which schedule is used on each day of the year,
    day_schs_used_each_day = schedule_ruleset.getActiveRuleIndices(year_start_date, year_end_date)

    # Create a map that shows how many days each schedule is used
    day_sch_freq = day_schs_used_each_day.group_by { |n| n }
    day_sch_freq = day_sch_freq.sort_by { |freq| freq[1].size }
    common_day_freq = day_sch_freq.last

    # Build a hash that maps schedule day index to schedule day
    schedule_index_to_day = {}
    day_schs.each_with_index do |day_sch, i|
      schedule_index_to_day[day_schs_used_each_day[i]] = day_sch
    end

    # Get the most common day schedule
    sch_index = common_day_freq[0]
    number_of_days_sch_used = common_day_freq[1].size

    # Get the day schedule at this index
    day_sch = if sch_index == -1 # If index = -1, this day uses the default day schedule (not a rule)
                schedule_ruleset.defaultDaySchedule
              else
                schedule_index_to_day[sch_index]
              end

    # Determine the full load hours for just one day
    values = []
    times = []
    day_sch.times.each_with_index do |time, i|
      times << day_sch.times[i]
      values << day_sch.values[i]
    end

    # Get the minimum value
    start_val = values.first
    end_val = values.last

    # Get the start time (first time value goes above minimum)
    start_time = nil
    values.each_with_index do |val, i|
      break if i == values.size - 1 # Stop if we reach end of array
      if val == start_val && values[i + 1] > start_val
        start_time = times[i + 1]
        break
      end
    end

    # Get the end time (first time value goes back down to minimum)
    end_time = nil
    values.each_with_index do |val, i|
      if i < values.size - 1
        if val > end_val && values[i + 1] == end_val
          end_time = times[i]
          break
        end
      else
        if val > end_val && values[0] == start_val # Check first hour of day for schedules that end at midnight
          end_time = OpenStudio::Time.new(0, 24, 0, 0)
          break
        end
      end
    end

    return [start_time, end_time]
  end

  # Check that the lighting, equipment, and HVAC setpoint schedules
  # coordinate with the occupancy schedules.  This is defined as having start and end
  # times within the specified number of hours away from the occupancy schedule.
  def check_sch_coord(category, target_standard, max_hrs, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Conditioned Zones')
    check_elems << OpenStudio::Attribute.new('category', category)
    check_elems << OpenStudio::Attribute.new('description', 'Check that lighting, equipment, and HVAC schedules coordinate with occupancy.')

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      results = []
      check_elems.each do |elem|
        results << elem.valueAsString
      end
      return results
    end

    std = Standard.build(target_standard)

    begin
      # Convert max hr limit to OpenStudio Time
      max_hrs = OpenStudio::Time.new(0, max_hrs, 0, 0)

      # Check schedules in each space
      @model.getSpaces.each do |space|
        # Occupancy, Lighting, and Equipment Schedules
        coord_schs = []
        occ_schs = []
        # Get the space type (optional)
        space_type = space.spaceType

        # Occupancy
        occs = []
        occs += space.people # From space directly
        occs += space_type.get.people if space_type.is_initialized # Inherited from space type
        occs.each do |occ|
          occ_schs << occ.numberofPeopleSchedule.get if occ.numberofPeopleSchedule.is_initialized
        end

        # Lights
        lts = []
        lts += space.lights # From space directly
        lts += space_type.get.lights if space_type.is_initialized # Inherited from space type
        lts.each do |lt|
          coord_schs << lt.schedule.get if lt.schedule.is_initialized
        end

        # Equip
        plugs = []
        plugs += space.electricEquipment # From space directly
        plugs += space_type.get.electricEquipment if space_type.is_initialized # Inherited from space type
        plugs.each do |plug|
          coord_schs << plug.schedule.get if plug.schedule.is_initialized
        end

        # HVAC Schedule (airloop-served zones only)
        if space.thermalZone.is_initialized
          zone = space.thermalZone.get
          if zone.airLoopHVAC.is_initialized
            coord_schs << zone.airLoopHVAC.get.availabilitySchedule
          end
        end

        # Cannot check spaces with no occupancy schedule to compare against
        next if occ_schs.empty?

        # Get start and end occupancy times from the first occupancy schedule
        occ_start_time, occ_end_time = get_start_and_end_times(occ_schs[0])

        # Cannot check a space where the occupancy start time or end time cannot be determined
        next if occ_start_time.nil? || occ_end_time.nil?

        # Check all schedules against occupancy

        # Lights should have a start and end within X hrs of the occupancy start and end
        coord_schs.each do |coord_sch|
          # Get start and end time of load/HVAC schedule
          start_time, end_time = get_start_and_end_times(coord_sch)
          if start_time.nil?
            check_elems << OpenStudio::Attribute.new('flag', "Could not determine start time of a schedule called #{coord_sch.name}, cannot determine if schedule coordinates with occupancy schedule.")
            next
          elsif end_time.nil?
            check_elems << OpenStudio::Attribute.new('flag', "Could not determine end time of a schedule called #{coord_sch.name}, cannot determine if schedule coordinates with occupancy schedule.")
            next
          end

          # Check start time
          if (occ_start_time - start_time) > max_hrs || (start_time - occ_start_time) > max_hrs
            check_elems << OpenStudio::Attribute.new('flag', "The start time of #{coord_sch.name} is #{start_time}, which is more than #{max_hrs} away from the occupancy schedule start time of #{occ_start_time} for #{occ_schs[0].name} in #{space.name}.  Schedules do not coordinate.")
          end

          # Check end time
          if (occ_end_time - end_time) > max_hrs || (end_time - occ_end_time) > max_hrs
            check_elems << OpenStudio::Attribute.new('flag', "The end time of #{coord_sch.name} is #{end_time}, which is more than #{max_hrs} away from the occupancy schedule end time of #{occ_end_time} for #{occ_schs[0].name} in #{space.name}.  Schedules do not coordinate.")
          end
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
end
