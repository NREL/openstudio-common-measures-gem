# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

module OsLib_QAQC
  # Check the fan power (W/cfm) for each air loop fan in the model to identify
  # unrealistically sized fans.
  def check_fan_pwr(category, target_standard, max_pwr_delta = 0.1, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Fan Power')
    check_elems << OpenStudio::Attribute.new('category', category)
    check_elems << OpenStudio::Attribute.new('description', 'Check that fan power vs flow makes sense.')

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
      # Check each air loop
      @model.getAirLoopHVACs.each do |plant_loop|
        # Set the expected W/cfm
        expected_w_per_cfm = 1.1

        # Check the W/cfm for each fan on each air loop
        plant_loop.supplyComponents.each do |sc|
          # Get the W/cfm for the fan
          obj_type = sc.iddObjectType.valueName.to_s
          case obj_type
          when 'OS_Fan_ConstantVolume'
            actual_w_per_cfm = std.fan_rated_w_per_cfm(sc.to_FanConstantVolume.get)
          when 'OS_Fan_OnOff'
            actual_w_per_cfm = std.fan_rated_w_per_cfm(sc.to_FanOnOff.get)
          when 'OS_Fan_VariableVolume'
            actual_w_per_cfm = std.fan_rated_w_per_cfm(sc.to_FanVariableVolume.get)
          else
            next # Skip non-fan objects
          end

          # Compare W/cfm to expected/typical values
          if ((expected_w_per_cfm - actual_w_per_cfm) / actual_w_per_cfm).abs > max_pwr_delta
            check_elems << OpenStudio::Attribute.new('flag', "For #{sc.name} on #{plant_loop.name}, the actual fan power of #{actual_w_per_cfm.round(1)} W/cfm is more than #{(max_pwr_delta * 100.0).round(2)}% different from the expected #{expected_w_per_cfm} W/cfm.")
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
