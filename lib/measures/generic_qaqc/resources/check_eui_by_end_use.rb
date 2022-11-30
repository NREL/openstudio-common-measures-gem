# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2022, Alliance for Sustainable Energy, LLC.
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
  def check_eui_by_end_use(category, target_standard, min_pass, max_pass, name_only = false)

    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'End Use by Category')
    check_elems << OpenStudio::Attribute.new('category', category)

    # update display sttandard
    if target_standard.include?('90.1')
      display_standard = "ASHRAE #{target_standard}"
    else
      display_standard = target_standard
    end

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      results = []
      check_elems << OpenStudio::Attribute.new('description', "Check model consumption by end use against #{target_standard} DOE prototype building.")
      check_elems.each do |elem|
        results << elem.valueAsString
      end
      return results
    end

    begin

      # setup standard
      std = Standard.build(target_standard)
      target_eui = std.model_find_target_eui(@model)

      # gather building type for summary
      if Gem::Version.new(OpenstudioStandards::VERSION) > Gem::Version.new('0.2.16')
        bt_cz = std.model_get_building_properties(@model)
      else
        bt_cz = std.model_get_building_climate_zone_and_building_type(@model)
      end
      building_type = bt_cz['building_type']
      # mapping to obuilding type to match space types
      if building_type.include?("Office") then building_type = "Office" end
      climate_zone = bt_cz['climate_zone']
      prototype_prefix = "#{display_standard} #{building_type} #{climate_zone}"
      check_elems << OpenStudio::Attribute.new('description', "Check model consumption by end use against #{prototype_prefix} DOE prototype building.")
      check_elems << OpenStudio::Attribute.new('min_pass', min_pass * 100)
      check_elems << OpenStudio::Attribute.new('max_pass', max_pass * 100)

      # total building area
      query = 'SELECT Value FROM tabulardatawithstrings WHERE '
      query << "ReportName='AnnualBuildingUtilityPerformanceSummary' and "
      query << "ReportForString='Entire Facility' and "
      query << "TableName='Building Area' and "
      query << "RowName='Total Building Area' and "
      query << "ColumnName='Area' and "
      query << "Units='m2';"
      query_results = @sql.execAndReturnFirstDouble(query)
      if query_results.empty?
        check_elems << OpenStudio::Attribute.new('flag', "Can't calculate EUI, SQL query for building area failed.")
        return OpenStudio::Attribute.new('check', check_elems)
      else
        energy_plus_area = query_results.get
      end

      # temp code to check OS vs. E+ area
      open_studio_area = @model.getBuilding.floorArea
      if (energy_plus_area - open_studio_area).abs >= 0.1
        check_elems << OpenStudio::Attribute.new('flag', "EnergyPlus reported area is #{energy_plus_area} (m^2). OpenStudio reported area is #{@model.getBuilding.floorArea} (m^2).")
      end

      # loop through end uses and gather consumption, normalized by floor area
      actual_eui_by_end_use = {}
      OpenStudio::EndUseCategoryType.getValues.each do |end_use|
        # get end uses
        end_use = OpenStudio::EndUseCategoryType.new(end_use).valueDescription

        total_end_use = 0
        OpenStudio::EndUseFuelType.getValues.each do |fuel_type|
          # convert integer to string
          fuel_name = OpenStudio::EndUseFuelType.new(fuel_type).valueDescription
          next if fuel_name == 'Water'
          query_fuel = "SELECT Value FROM tabulardatawithstrings WHERE ReportName='AnnualBuildingUtilityPerformanceSummary' and TableName='End Uses' and RowName= '#{end_use}' and ColumnName= '#{fuel_name}'"
          results_fuel = @sql.execAndReturnFirstDouble(query_fuel).get
          total_end_use += results_fuel
        end

        # populate hash for actual end use normalized by area
        actual_eui_by_end_use[end_use] = total_end_use / energy_plus_area
      end

      # check if all spaces types used the building type defined in the model (percentage calculation doesn't check if all area is inclued in building floor area)
      if building_type != ''
        primary_type_floor_area = 0.0
        non_pri_area = 0.0
        non_pri_types = []
        @model.getSpaceTypes.each do |space_type|
          st_bt = space_type.standardsBuildingType
          if st_bt.is_initialized
              st_bt = st_bt.get.to_s
              if st_bt.include?("Office") then st_bt = "Office" end
              if st_bt.to_s == building_type.to_s
                primary_type_floor_area += space_type.floorArea
              else
                non_pri_area += space_type.floorArea
                if !non_pri_types.include?(st_bt) then non_pri_types << st_bt end
              end
          else
            non_pri_area += space_type.floorArea
            if !non_pri_types.include?(st_bt) then non_pri_types << st_bt end
          end
        end
        if non_pri_area > 0.0
          check_elems << OpenStudio::Attribute.new('flag', "The primary building type, #{building_type}, only represents #{(100 * primary_type_floor_area / (primary_type_floor_area + non_pri_area)).round}% of the total building area. Other standads building types included are #{non_pri_types.sort.join(",")}. While a comparison to the #{building_type} prototype consumption by end use is provided, it would not be unexpected for the building consumption by end use to be significantly different than the prototype.")
        end
      end

      # gather target end uses for given standard as hash
      std = Standard.build(target_standard)
      target_eui_by_end_use = std.model_find_target_eui_by_end_use(@model)

      # units for flag display text and unit conversion
      source_units = 'GJ/m^2'
      target_units = 'kBtu/ft^2'

      # check acutal vs. target against tolerance
      if !target_eui_by_end_use.nil?
        actual_eui_by_end_use.each do |end_use, value|
          # this should have value of 0 in model. This page change in the future. It doesn't exist in target lookup
          next if end_use == 'Exterior Equipment'

          # perform check and issue flags as needed
          target_value = target_eui_by_end_use[end_use]
          eui_ip_neat = OpenStudio.toNeatString(OpenStudio.convert(value, source_units, target_units).get, 5, true)
          target_eui_ip_neat = OpenStudio.toNeatString(OpenStudio.convert(target_value, source_units, target_units).get, 1, true)

          # add in use case specific logic to skip checks when near 0 actual and target
          skip = false
          if (end_use == 'Heat Recovery') && (value < 0.05) && (target_value < 0.05) then skip = true end
          if (end_use == 'Pumps') && (value < 0.05) && (target_value < 0.05) then skip = true end

          if (value < target_value * (1.0 - min_pass)) && !skip
            check_elems << OpenStudio::Attribute.new('flag', "#{end_use} EUI of #{eui_ip_neat} (#{target_units}) is more than #{min_pass * 100} % below the #{prototype_prefix} prototype #{end_use} EUI of #{target_eui_ip_neat} (#{target_units}) for #{target_standard}.")
          elsif (value > target_value * (1.0 + max_pass)) && !skip
            check_elems << OpenStudio::Attribute.new('flag', "#{end_use} EUI of #{eui_ip_neat} (#{target_units}) is more than #{max_pass * 100} % above the #{prototype_prefix} prototype #{end_use} EUI of #{target_eui_ip_neat} (#{target_units}) for #{target_standard}.")
          end
        end
      else
        if ['90.1-2016','90.1-2019'].include?(target_standard) || target_standard.include?("ComStock")
          check_elems << OpenStudio::Attribute.new('flag', "target EUI end use comparison is not supported yet for #{target_standard}.")
        else
          check_elems << OpenStudio::Attribute.new('flag', "Can't calculate target end use EUIs. Make sure model has expected climate zone and building type.")
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
