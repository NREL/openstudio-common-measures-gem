# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

module OsLib_QAQC
  # include any general notes about QAQC method here

  # checks the number of unmet hours in the model
  def check_mech_sys_type(category, target_standard, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Baseline Mechanical System Type')
    check_elems << OpenStudio::Attribute.new('category', category)

    # add ASHRAE to display of target standard if includes with 90.1
    if target_standard.include?('90.1 2013')
      check_elems << OpenStudio::Attribute.new('description', 'Check against ASHRAE 90.1 2013 Tables G3.1.1 A-B. Infers the baseline system type based on the equipment serving the zone and their heating/cooling fuels. Only does a high-level inference; does not look for the presence/absence of required controls, etc.')
    else
      check_elems << OpenStudio::Attribute.new('description', 'Check against ASHRAE 90.1. Infers the baseline system type based on the equipment serving the zone and their heating/cooling fuels. Only does a high-level inference; does not look for the presence/absence of required controls, etc.')
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
      # Get the actual system type for all zones in the model
      act_zone_to_sys_type = {}
      @model.getThermalZones.each do |zone|
        if use_old_gem_code
          act_zone_to_sys_type[zone] = zone.infer_system_type
        else
          act_zone_to_sys_type[zone] = std.thermal_zone_infer_system_type(zone)
        end
      end

      # Get the baseline system type for all zones in the model
      if use_old_gem_code
        climate_zone = @model.get_building_climate_zone_and_building_type['climate_zone']
      else
        if Gem::Version.new(OpenstudioStandards::VERSION) > Gem::Version.new('0.2.16')
          climate_zone = std.model_get_building_properties(@model)['climate_zone']
        else
          climate_zone = std.model_get_building_climate_zone_and_building_type(@model)['climate_zone']
        end
      end

      if use_old_gem_code
        req_zone_to_sys_type = @model.get_baseline_system_type_by_zone(target_standard, climate_zone)
      else
        req_zone_to_sys_type = std.model_get_baseline_system_type_by_zone(@model, climate_zone)
      end

      # Compare the actual to the correct
      @model.getThermalZones.each do |zone|
        # TODO: - skip if plenum
        is_plenum = false
        zone.spaces.each do |space|
          if use_old_gem_code
            if space.plenum?
              is_plenum = true
            end
          else
            if std.space_plenum?(space)
              is_plenum = true
            end
          end
        end
        next if is_plenum

        req_sys_type = req_zone_to_sys_type[zone]
        act_sys_type = act_zone_to_sys_type[zone]

        if act_sys_type == req_sys_type
          puts "#{zone.name} system type = #{act_sys_type}"
        else
          if req_sys_type == '' then req_sys_type = 'Unknown' end
          puts "#{zone.name} baseline system type is incorrect. Supposed to be #{req_sys_type}, but was #{act_sys_type} instead."
          check_elems << OpenStudio::Attribute.new('flag', "For #{zone.name}, the baseline system type would be #{req_sys_type}; the current system type is #{act_sys_type}.")
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
