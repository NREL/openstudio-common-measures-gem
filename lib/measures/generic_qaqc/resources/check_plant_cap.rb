# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

module OsLib_QAQC
  # Check primary plant loop heating and cooling equipment capacity against
  # coil loads to find equipment that is significantly oversized or undersized.
  def check_plant_cap(category, target_standard, max_pct_delta = 0.1, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Plant Capacity')
    check_elems << OpenStudio::Attribute.new('category', category)
    check_elems << OpenStudio::Attribute.new('description', 'Check that plant equipment capacity matches loads.')

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
      # Check the heating and cooling capacity of the plant loops against their coil loads
      @model.getPlantLoops.each do |plant_loop|
        # Heating capacity
        htg_cap_w = std.plant_loop_total_heating_capacity(plant_loop)

        # Cooling capacity
        clg_cap_w = std.plant_loop_total_cooling_capacity(plant_loop)

        # Heating and cooling loads
        plant_loop.demandComponents.each do |dc|
          # Get the load for each coil
          htg_load_w = 0.0
          clg_load_w = 0.0
          obj_type = sc.iddObjectType.valueName.to_s
          case obj_type
          when 'OS_Coil_Heating_Water'
            coil = sc.to_CoilHeatingWater.get
            if coil.ratedCapacity.is_initialized
              clg_load_w += coil.ratedCapacity.get
            elsif coil.autosizedRatedCapacity.is_initialized
              clg_load_w += coil.autosizedRatedCapacity.get
            end
          when 'OS_Coil_Cooling_Water'
            coil = sc.to_CoilCoolingWater.get
            if coil.autosizedDesignCoilLoad.is_initialized
              clg_load_w += coil.autosizedDesignCoilLoad.get
            end
          end
        end

        # Don't check loops with no loads.  These are probably
        # SWH or non-typical loops that can't be checked by simple methods.

        # Heating
        if htg_load_w > 0
          htg_cap_kbtu_per_hr = OpenStudio.convert(htg_cap_w, 'W', 'kBtu/hr').get.round(1)
          htg_load_kbtu_per_hr = OpenStudio.convert(htg_load_w, 'W', 'kBtu/hr').get.round(1)
          if ((htg_cap_w - htg_load_w) / htg_cap_w).abs > max_pct_delta
            check_elems << OpenStudio::Attribute.new('flag', "For #{plant_loop.name}, the total heating capacity of #{htg_cap_kbtu_per_hr} kBtu/hr is more than #{(max_pct_delta * 100.0).round(2)}% different from the combined coil load of #{htg_load_kbtu_per_hr} kBtu/hr.  This could indicate significantly oversized or undersized equipment.")
          end
        end

        # Cooling
        if clg_load_w > 0
          clg_cap_tons = OpenStudio.convert(clg_cap_w, 'W', 'ton').get.round(1)
          clg_load_tons = OpenStudio.convert(clg_load_w, 'W', 'ton').get.round(1)
          if ((clg_cap_w - clg_load_w) / clg_cap_w).abs > max_pct_delta
            check_elems << OpenStudio::Attribute.new('flag', "For #{plant_loop.name}, the total cooling capacity of #{clg_cap_kbtu_per_hr} tons is more than #{(max_pct_delta * 100.0).round(2)}% different from the combined coil load of #{clg_load_kbtu_per_hr} tons.  This could indicate significantly oversized or undersized equipment.")
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
