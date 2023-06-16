# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

module OsLib_QAQC
  # Check the pumping power (W/gpm) for each pump in the model to identify
  # unrealistically sized pumps.
  def check_pump_pwr(category, target_standard, max_pwr_delta = 0.1, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Pump Power')
    check_elems << OpenStudio::Attribute.new('category', category)
    check_elems << OpenStudio::Attribute.new('description', 'Check that pump power vs flow makes sense.')

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
      # Check each plant loop
      @model.getPlantLoops.each do |plant_loop|
        # Set the expected/typical W/gpm
        loop_type = plant_loop.sizingPlant.loopType
        case loop_type
        when 'Heating'
          expected_w_per_gpm = 19.0
        when 'Cooling'
          expected_w_per_gpm = 22.0
        when 'Condenser'
          expected_w_per_gpm = 19.0
        end

        # Check the W/gpm for each pump on each plant loop
        plant_loop.supplyComponents.each do |sc|
          # Get the W/gpm for the pump
          obj_type = sc.iddObjectType.valueName.to_s
          case obj_type
          when 'OS_Pump_ConstantSpeed'
            actual_w_per_gpm = std.pump_rated_w_per_gpm(sc.to_PumpConstantSpeed.get)
          when 'OS_Pump_VariableSpeed'
            actual_w_per_gpm = std.pump_rated_w_per_gpm(sc.to_PumpVariableSpeed.get)
          when 'OS_HeaderedPumps_ConstantSpeed'
            actual_w_per_gpm = std.pump_rated_w_per_gpm(sc.to_HeaderedPumpsConstantSpeed.get)
          when 'OS_HeaderedPumps_VariableSpeed'
            actual_w_per_gpm = std.pump_rated_w_per_gpm(sc.to_HeaderedPumpsVariableSpeed.get)
          else
            next # Skip non-pump objects
          end

          # Compare W/gpm to expected/typical values
          if ((expected_w_per_gpm - actual_w_per_gpm) / actual_w_per_gpm).abs > max_pwr_delta
            check_elems << OpenStudio::Attribute.new('flag', "For #{sc.name} on #{plant_loop.name}, the actual pumping power of #{actual_w_per_gpm.round(1)} W/gpm is more than #{(max_pwr_delta * 100.0).round(2)}% different from the expected #{expected_w_per_gpm} W/gpm for a #{loop_type} plant loop.")
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
