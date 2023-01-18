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
  def check_eui_reasonableness(category, target_standard, min_pass, max_pass, name_only = false)

    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'EUI Reasonableness')
    check_elems << OpenStudio::Attribute.new('category', category)

    # update display sttandard
    if target_standard.include?('90.1')
      display_standard = "ASHRAE #{target_standard}"
    else
      display_standard = target_standard
    end

    # stop here if only name is requested this is used to populate display name for arguments
    if name_only == true
      check_elems << OpenStudio::Attribute.new('description', "Check model EUI against #{display_standard} DOE prototype building.")
      results = []
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
      climate_zone = bt_cz['climate_zone']
      prototype_prefix = "#{display_standard} #{building_type} #{climate_zone}"

      # mapping to obuilding type to match space types
      if building_type.include?("Office") then building_type = "Office" end

      # last part of summary table
      check_elems << OpenStudio::Attribute.new('description', "Check model EUI against #{prototype_prefix} DOE prototype building.")
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

      # EUI
      source_units = 'GJ/m^2'
      target_units = 'kBtu/ft^2'
      if energy_plus_area > 0.0 # don't calculate EUI if building doesn't have any area
        # todo -  netSiteEnergy deducts for renewable. May want to update this to show gross consumption vs. net consumption
        eui = @sql.netSiteEnergy.get / energy_plus_area
      else
        check_elems << OpenStudio::Attribute.new('flag', "Can't calculate model EUI, building doesn't have any floor area.")
        return OpenStudio::Attribute.new('check', check_elems)
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
          check_elems << OpenStudio::Attribute.new('flag', "The primary building type, #{building_type}, only represents #{(100 * primary_type_floor_area / (primary_type_floor_area + non_pri_area)).round}% of the total building area. Other standads building types included are #{non_pri_types.sort.join(",")}. While a comparison to the #{building_type} prototype EUI is provided, it would not be unexpected for the building EUI to be significantly different than the prototype.")
        end
      end

      # check model vs. target for user specified tolerance.
      if !target_eui.nil?
        eui_ip_neat = OpenStudio.toNeatString(OpenStudio.convert(eui, source_units, target_units).get, 1, true)
        target_eui_ip_neat = OpenStudio.toNeatString(OpenStudio.convert(target_eui, source_units, target_units).get, 1, true)
        if eui < target_eui * (1.0 - min_pass)
          check_elems << OpenStudio::Attribute.new('flag', "Model EUI of #{eui_ip_neat} (#{target_units}) is more than #{min_pass * 100} % below the #{prototype_prefix} prototype EUI of #{target_eui_ip_neat} (#{target_units}).")
        elsif eui > target_eui * (1.0 + max_pass)
          check_elems << OpenStudio::Attribute.new('flag', "Model EUI of #{eui_ip_neat} (#{target_units}) is more than #{max_pass * 100} % above the #{prototype_prefix} prototype EUI of #{target_eui_ip_neat} (#{target_units}).")
        end
      else
        if ['90.1-2016','90.1-2019'].include?(target_standard) || target_standard.include?("ComStock")
          check_elems << OpenStudio::Attribute.new('flag', "target EUI comparison is not supported yet for #{target_standard}.")
        else
          check_elems << OpenStudio::Attribute.new('flag', "Can't calculate target EUI. Make sure model has expected climate zone and building type.")
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
