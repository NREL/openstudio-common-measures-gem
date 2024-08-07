# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

module OsLib_QAQC
  # include any general notes about QAQC method here

  # checks the number of unmet hours in the model
  def check_supply_air_and_thermostat_temp_difference(category, target_standard, max_delta, name_only = false)
    # G3.1.2.9 requires a 20 degree F delta between supply air temperature and zone temperature.
    target_clg_delta = 20.0

    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Supply and Zone Air Temperature')
    check_elems << OpenStudio::Attribute.new('category', category)
    if @utility_name.nil?
      check_elems << OpenStudio::Attribute.new('description', "Check if fans modeled to ASHRAE 90.1 2013 Section G3.1.2.9 requirements. Compare the supply air temperature for each thermal zone against the thermostat setpoints. Throw flag if temperature difference excedes threshold of #{target_clg_delta}F plus the selected tolerance.")
    else
      check_elems << OpenStudio::Attribute.new('description', "Check if fans modeled to ASHRAE 90.1 2013 Section G3.1.2.9 requirements. Compare the supply air temperature for each thermal zone against the thermostat setpoints. Throw flag if temperature difference excedes threshold set by #{@utility_name}.")
    end
    check_elems << OpenStudio::Attribute.new('min_pass', max_delta)
    
    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      results = []
      check_elems.each do |elem|
        next if ['Double','Integer'].include? (elem.valueType.valueDescription)
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
      # loop through thermal zones
      @model.getThermalZones.sort.each do |thermal_zone|
        model_clg_min = nil

        # populate thermostat ranges
        if thermal_zone.thermostatSetpointDualSetpoint.is_initialized

          thermostat = thermal_zone.thermostatSetpointDualSetpoint.get
          if thermostat.coolingSetpointTemperatureSchedule.is_initialized

            clg_sch = thermostat.coolingSetpointTemperatureSchedule.get
            schedule_values = nil
            if clg_sch.to_ScheduleRuleset.is_initialized
              if use_old_gem_code
                schedule_values = clg_sch.to_ScheduleRuleset.get.annual_min_max_value
              else
                schedule_values = OpenstudioStandards::Schedules.schedule_get_min_max(clg_sch)
              end
            elsif clg_sch.to_ScheduleConstant.is_initialized
              if use_old_gem_code
                schedule_values = clg_sch.to_ScheduleConstant.get.annual_min_max_value
              else
                schedule_values = OpenstudioStandards::Schedules.schedule_get_min_max(clg_sch)
              end
            end

            unless schedule_values.nil?
              puts "hello1"
              puts schedule_values
              puts "hello2"
              model_clg_min = schedule_values['min']
            end
          end

        else
          # go to next zone if not conditioned
          next

        end

        # flag if there is setpoint schedule can't be inspected (isn't ruleset)
        if model_clg_min.nil?
          check_elems << OpenStudio::Attribute.new('flag', "Can't inspect thermostat schedules for #{thermal_zone.name}")
        else

          # get supply air temps from thermal zone sizing
          sizing_zone = thermal_zone.sizingZone
          clg_supply_air_temp = sizing_zone.zoneCoolingDesignSupplyAirTemperature

          # convert model values to IP
          model_clg_min_ip = OpenStudio.convert(model_clg_min, 'C', 'F').get
          clg_supply_air_temp_ip = OpenStudio.convert(clg_supply_air_temp, 'C', 'F').get

          # check supply air against zone temperature (only check against min setpoint, assume max is night setback)
          if model_clg_min_ip - clg_supply_air_temp_ip > target_clg_delta + max_delta
            check_elems << OpenStudio::Attribute.new('flag', "For #{thermal_zone.name} the delta temp between the cooling supply air temp of #{clg_supply_air_temp_ip.round(2)} (F) and the minimum thermostat cooling temp of #{model_clg_min_ip.round(2)} (F) is more than #{max_delta} (F) larger than the expected delta of #{target_clg_delta} (F)")
          elsif model_clg_min_ip - clg_supply_air_temp_ip < target_clg_delta - max_delta
            check_elems << OpenStudio::Attribute.new('flag', "For #{thermal_zone.name} the delta temp between the cooling supply air temp of #{clg_supply_air_temp_ip.round(2)} (F) and the minimum thermostat cooling temp of #{model_clg_min_ip.round(2)} (F) is more than #{max_delta} (F) smaller than the expected delta of #{target_clg_delta} (F)")
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
