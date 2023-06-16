# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

module OsLib_QAQC
  # Check that there are no people or lights in plenums.
  def check_plenum_loads(category, target_standard, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Plenum Loads')
    check_elems << OpenStudio::Attribute.new('category', category)
    check_elems << OpenStudio::Attribute.new('description', 'Check that the plenums do not have people or lights.')

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
        # Only check plenums
        next unless std.thermal_zone_plenum?(zone)

        # People
        num_people = zone.numberOfPeople
        if num_people > 0
          check_elems << OpenStudio::Attribute.new('flag', "#{zone.name} is a plenum, but has #{num_people.round(1)} people.  Plenums should not contain people.")
        end

        # Lights
        lights_w = zone.lightingPower
        if lights_w > 0
          check_elems << OpenStudio::Attribute.new('flag', "#{zone.name} is a plenum, but has #{lights_w.round(1)} W of lights.  Plenums should not contain lights.")
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
