# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

module OsLib_QAQC
  # Check that all zones with people are conditioned (have a thermostat with setpoints)
  def check_cond_zns(category, target_standard, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Conditioned Zones')
    check_elems << OpenStudio::Attribute.new('category', category)
    check_elems << OpenStudio::Attribute.new('description', 'Check that all zones with people have thermostats.')
    check_elems << OpenStudio::Attribute.new('min_pass', "#{(min_pass * 100).round(0)}")
    check_elems << OpenStudio::Attribute.new('max_pass', "#{(max_pass * 100).round(0)}")
    
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
      @model.getThermalZones.each do |zone|
        # Only check zones that have people
        num_ppl = zone.numberOfPeople
        next unless zone.numberOfPeople > 0

        # Check that the zone is heated (at a minimum)
        # by checking that the heating setpoint is at least 41F.
        # Sometimes people include thermostats but set the setpoints
        # such that the system never comes on.  This check attempts to catch that.
        unless std.thermal_zone_heated?(zone)
          check_elems << OpenStudio::Attribute.new('flag', "#{zone.name} has #{num_ppl} people but is not heated.  Zones containing people are expected to be conditioned, heated-only at a minimum.  Heating setpoint must be at least 41F to be considered heated.")
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
