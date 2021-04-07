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
  def check_mech_sys_capacity(category, options, target_standard, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Mechanical System Capacity')
    check_elems << OpenStudio::Attribute.new('category', category)
    check_elems << OpenStudio::Attribute.new('description', 'Check HVAC capacity against ASHRAE rules of thumb for chiller max flow rate, air loop max flow rate, air loop cooling capciaty, and zone heating capcaity. Zone heating check will skip thermal zones without any exterior exposure, and thermal zones that are not conditioned.')

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
      # check max flow rate of chillers in model
      @model.getPlantLoops.sort.each do |plant_loop|
        # next if no chiller on plant loop
        chillers = []
        plant_loop.supplyComponents.each do |sc|
          if sc.to_ChillerElectricEIR.is_initialized
            chillers << sc.to_ChillerElectricEIR.get
          end
        end
        next if chillers.empty?

        # gather targets for chiller capacity
        chiller_max_flow_rate_target = options['chiller_max_flow_rate']['target']
        chiller_max_flow_rate_fraction_min = options['chiller_max_flow_rate']['min']
        chiller_max_flow_rate_fraction_max = options['chiller_max_flow_rate']['max']
        chiller_max_flow_rate_units_ip = options['chiller_max_flow_rate']['units'] # gal/ton*min
        # string above or display only, for converstion 12000 Btu/h per ton

        # get capacity of loop (not individual chiller but entire loop)
        if use_old_gem_code
          total_cooling_capacity_w = plant_loop.total_cooling_capacity
        else
          total_cooling_capacity_w = std.plant_loop_total_cooling_capacity(plant_loop)
        end
        total_cooling_capacity_ton = OpenStudio.convert(total_cooling_capacity_w, 'W', 'Btu/h').get / 12000.0

        # get the max flow rate (through plant, not specific chiller)
        if use_old_gem_code
          maximum_loop_flow_rate = plant_loop.find_maximum_loop_flow_rate
        else
          maximum_loop_flow_rate = std.plant_loop_find_maximum_loop_flow_rate(plant_loop)
        end
        maximum_loop_flow_rate_ip = OpenStudio.convert(maximum_loop_flow_rate, 'm^3/s', 'gal/min').get

        # calculate the flow per tons of cooling
        model_flow_rate_per_ton_cooling_ip = maximum_loop_flow_rate_ip / total_cooling_capacity_ton

        # check flow rate per capacity
        if model_flow_rate_per_ton_cooling_ip < chiller_max_flow_rate_target * (1.0 - chiller_max_flow_rate_fraction_min)
          check_elems <<  OpenStudio::Attribute.new('flag', "Flow Rate of #{model_flow_rate_per_ton_cooling_ip.round(2)} #{chiller_max_flow_rate_units_ip} for #{plant_loop.name.get} is more than #{chiller_max_flow_rate_fraction_min * 100} % below the typical value of #{chiller_max_flow_rate_target.round(2)} #{chiller_max_flow_rate_units_ip}.")
        elsif model_flow_rate_per_ton_cooling_ip > chiller_max_flow_rate_target * (1.0 + chiller_max_flow_rate_fraction_max)
          check_elems <<  OpenStudio::Attribute.new('flag', "Flow Rate of #{model_flow_rate_per_ton_cooling_ip.round(2)} #{chiller_max_flow_rate_units_ip} for #{plant_loop.name.get} is more than #{chiller_max_flow_rate_fraction_max * 100} % above the typical value of #{chiller_max_flow_rate_target.round(2)} #{chiller_max_flow_rate_units_ip}.")
        end
      end

      # loop through air loops to get max flor rate and cooling capacity.
      @model.getAirLoopHVACs.sort.each do |air_loop|
        # TODO: - check if DOAS, don't check airflow or cooling capacity if it is (why not check OA for DOAS? would it be different target)

        # gather argument options for air_loop_max_flow_rate checks
        air_loop_max_flow_rate_target = options['air_loop_max_flow_rate']['target']
        air_loop_max_flow_rate_fraction_min = options['air_loop_max_flow_rate']['min']
        air_loop_max_flow_rate_fraction_max = options['air_loop_max_flow_rate']['max']
        air_loop_max_flow_rate_units_ip = options['air_loop_max_flow_rate']['units']
        air_loop_max_flow_rate_units_si = 'm^3/m^2*s'

        # get values from model for air loop checks
        if use_old_gem_code
          floor_area_served = air_loop.floor_area_served # m^2
        else
          floor_area_served = std.air_loop_hvac_floor_area_served(air_loop) # m^2
        end

        if use_old_gem_code
          design_supply_air_flow_rate = air_loop.find_design_supply_air_flow_rate # m^3/s
        else
          design_supply_air_flow_rate = std.air_loop_hvac_find_design_supply_air_flow_rate(air_loop) # m^3/s
        end

        # check max flow rate of air loops in the model
        model_normalized_flow_rate_si = design_supply_air_flow_rate / floor_area_served
        model_normalized_flow_rate_ip = OpenStudio.convert(model_normalized_flow_rate_si, air_loop_max_flow_rate_units_si, air_loop_max_flow_rate_units_ip).get
        if model_normalized_flow_rate_ip < air_loop_max_flow_rate_target * (1.0 - air_loop_max_flow_rate_fraction_min)
          check_elems <<  OpenStudio::Attribute.new('flag', "Flow Rate of #{model_normalized_flow_rate_ip.round(2)} #{air_loop_max_flow_rate_units_ip} for #{air_loop.name.get} is more than #{air_loop_max_flow_rate_fraction_min * 100} % below the typical value of #{air_loop_max_flow_rate_target.round(2)} #{air_loop_max_flow_rate_units_ip}.")
        elsif model_normalized_flow_rate_ip > air_loop_max_flow_rate_target * (1.0 + air_loop_max_flow_rate_fraction_max)
          check_elems <<  OpenStudio::Attribute.new('flag', "Flow Rate of #{model_normalized_flow_rate_ip.round(2)} #{air_loop_max_flow_rate_units_ip} for #{air_loop.name.get} is more than #{air_loop_max_flow_rate_fraction_max * 100} % above the typical value of #{air_loop_max_flow_rate_target.round(2)} #{air_loop_max_flow_rate_units_ip}.")
        end
      end

      # loop through air loops to get max flor rate and cooling capacity.
      @model.getAirLoopHVACs.sort.each do |air_loop|
        # check if DOAS, don't check airflow or cooling capacity if it is
        sizing_system = air_loop.sizingSystem
        next if sizing_system.typeofLoadtoSizeOn.to_s == 'VentilationRequirement'

        # gather argument options for air_loop_cooling_capacity checks
        air_loop_cooling_capacity_target = options['air_loop_cooling_capacity']['target']
        air_loop_cooling_capacity_fraction_min = options['air_loop_cooling_capacity']['min']
        air_loop_cooling_capacity_fraction_max = options['air_loop_cooling_capacity']['max']
        air_loop_cooling_capacity_units_ip = options['air_loop_cooling_capacity']['units'] # tons/ft^2
        # string above or display only, for converstion 12000 Btu/h per ton
        air_loop_cooling_capacity_units_si = 'W/m^2'

        # get values from model for air loop checks
        if use_old_gem_code
          floor_area_served = air_loop.floor_area_served # m^2
        else
          floor_area_served = std.air_loop_hvac_floor_area_served(air_loop) # m^2
        end

        if use_old_gem_code
          capacity = air_loop.total_cooling_capacity # W
        else
          capacity = std.air_loop_hvac_total_cooling_capacity(air_loop) # W
        end

        # check cooling capacity of air loops in the model
        model_normalized_capacity_si = capacity / floor_area_served
        model_normalized_capacity_ip = OpenStudio.convert(model_normalized_capacity_si, air_loop_cooling_capacity_units_si, 'Btu/ft^2*h').get / 12000.0 # hard coded to get tons from Btu/h

        # want to display in tons/ft^2 so invert number and display for checks
        model_tons_per_area_ip = 1.0 / model_normalized_capacity_ip
        target_tons_per_area_ip = 1.0 / air_loop_cooling_capacity_target
        inverted_units = 'ft^2/ton'

        if model_tons_per_area_ip < target_tons_per_area_ip * (1.0 - air_loop_cooling_capacity_fraction_max)
          check_elems <<  OpenStudio::Attribute.new('flag', "Cooling Capacity of #{model_tons_per_area_ip.round} #{inverted_units} for #{air_loop.name.get} is more than #{air_loop_cooling_capacity_fraction_max * 100} % below the typical value of #{target_tons_per_area_ip.round} #{inverted_units}.")
        elsif model_tons_per_area_ip > target_tons_per_area_ip * (1.0 + air_loop_cooling_capacity_fraction_min)
          check_elems <<  OpenStudio::Attribute.new('flag', "Cooling Capacity of #{model_tons_per_area_ip.round} #{inverted_units} for #{air_loop.name.get} is more than #{air_loop_cooling_capacity_fraction_min * 100} % above the typical value of #{target_tons_per_area_ip.round} #{inverted_units}.")
        end
      end

      # check heating capacity of thermal zones in the model with exterior exposure
      report_name = 'HVACSizingSummary'
      table_name = 'Zone Sensible Heating'
      column_name = 'User Design Load per Area'
      target = options['zone_heating_capacity']['target']
      fraction_min = options['zone_heating_capacity']['min']
      fraction_max = options['zone_heating_capacity']['max']
      units_ip = options['zone_heating_capacity']['units']
      units_si = 'W/m^2'
      @model.getThermalZones.sort.each do |thermal_zone|
        next if thermal_zone.canBePlenum
        next if thermal_zone.exteriorSurfaceArea == 0.0
        query = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='#{report_name}' and TableName='#{table_name}' and RowName= '#{thermal_zone.name.get.upcase}' and ColumnName= '#{column_name}'"
        results = @sql.execAndReturnFirstDouble(query) # W/m^2
        model_zone_heating_capacity_ip = OpenStudio.convert(results.to_f, units_si, units_ip).get
        # check actual against target
        if model_zone_heating_capacity_ip < target * (1.0 - fraction_min)
          check_elems <<  OpenStudio::Attribute.new('flag', "Heating Capacity of #{model_zone_heating_capacity_ip.round(2)} Btu/ft^2*h for #{thermal_zone.name.get} is more than #{fraction_min * 100} % below the typical value of #{target.round(2)} Btu/ft^2*h.")
        elsif model_zone_heating_capacity_ip > target * (1.0 + fraction_max)
          check_elems <<  OpenStudio::Attribute.new('flag', "Heating Capacity of #{model_zone_heating_capacity_ip.round(2)} Btu/ft^2*h for #{thermal_zone.name.get} is more than #{fraction_max * 100} % above the typical value of #{target.round(2)} Btu/ft^2*h.")
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
