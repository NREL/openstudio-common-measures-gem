# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
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
  # Check the air loop and zone operational vs. sizing temperatures
  # and make sure everything is coordinated.  This identifies problems
  # caused by sizing to one set of conditions and operating at a different set.
  def check_air_sys_temps(category, target_standard, max_sizing_temp_delta = 0.1, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Air System Temperatures')
    check_elems << OpenStudio::Attribute.new('category', category)
    check_elems << OpenStudio::Attribute.new('description', 'Check that air system sizing and operation temperatures are coordinated.')

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
      # Check each air loop in the model
      @model.getAirLoopHVACs.sort.each do |airloop|
        loop_name = airloop.name.to_s

        # Get the central heating and cooling SAT for sizing
        sizing_system = airloop.sizingSystem
        loop_siz_htg_f = OpenStudio.convert(sizing_system.centralHeatingDesignSupplyAirTemperature, 'C', 'F').get
        loop_siz_clg_f = OpenStudio.convert(sizing_system.centralCoolingDesignSupplyAirTemperature, 'C', 'F').get

        # Compare air loop to zone sizing temperatures
        airloop.thermalZones.each do |zone|
          # If this zone has a reheat terminal, get the reheat temp for comparison
          reheat_op_f = nil
          reheat_zone = false
          zone.equipment.each do |equip|
            obj_type = equip.iddObjectType.valueName.to_s
            case obj_type
            when 'OS_AirTerminal_SingleDuct_ConstantVolume_Reheat'
              term = equip.to_AirTerminalSingleDuctConstantVolumeReheat.get
              reheat_op_f = OpenStudio.convert(term.maximumReheatAirTemperature, 'C', 'F').get
              reheat_zone = true
            when 'OS_AirTerminal_SingleDuct_VAV_HeatAndCool_Reheat'
              term = equip.to_AirTerminalSingleDuctVAVHeatAndCoolReheat.get
              reheat_op_f = OpenStudio.convert(term.maximumReheatAirTemperature, 'C', 'F').get
              reheat_zone = true
            when 'OS_AirTerminal_SingleDuct_VAV_Reheat'
              term = equip.to_AirTerminalSingleDuctVAVReheat.get
              reheat_op_f = OpenStudio.convert(term.maximumReheatAirTemperature, 'C', 'F').get
              reheat_zone = true
            when 'OS_AirTerminal_SingleDuct_ParallelPIU_Reheat'
              term = equip.to_AirTerminalSingleDuctParallelPIUReheat.get
              # reheat_op_f = # Not an OpenStudio input
              reheat_zone = true
            when 'OS_AirTerminal_SingleDuct_SeriesPIU_Reheat'
              term = equip.to_AirTerminalSingleDuctSeriesPIUReheat.get
              # reheat_op_f = # Not an OpenStudio input
              reheat_zone = true
            end
          end

          # Get the zone heating and cooling SAT for sizing
          sizing_zone = zone.sizingZone
          zone_siz_htg_f = OpenStudio.convert(sizing_zone.zoneHeatingDesignSupplyAirTemperature, 'C', 'F').get
          zone_siz_clg_f = OpenStudio.convert(sizing_zone.zoneCoolingDesignSupplyAirTemperature, 'C', 'F').get

          # Check cooling temperatures
          if ((loop_siz_clg_f - zone_siz_clg_f) / loop_siz_clg_f).abs > max_sizing_temp_delta
            check_elems << OpenStudio::Attribute.new('flag', "For #{zone.name}, the sizing for the air loop is done with a cooling supply air temp of #{loop_siz_clg_f.round(2)}F, but the sizing for the zone is done with a cooling supply air temp of #{zone_siz_clg_f.round(2)}F. These are farther apart than the acceptable #{(max_sizing_temp_delta * 100.0).round(2)}% difference.")
          end

          # Check heating temperatures
          if reheat_zone && reheat_op_f
            if ((reheat_op_f - zone_siz_htg_f) / reheat_op_f).abs > max_sizing_temp_delta
              check_elems << OpenStudio::Attribute.new('flag', "For #{zone.name}, the reheat air temp is set to #{reheat_op_f.round(2)}F, but the sizing for the zone is done with a heating supply air temp of #{zone_siz_htg_f.round(2)}F. These are farther apart than the acceptable #{(max_sizing_temp_delta * 100.0).round(2)}% difference.")
            end
          elsif reheat_zone && !reheat_op_f
            # Don't perform the check if it is a reheat zone but the reheat temperature
            # is not available from the model inputs
          else
            if ((loop_siz_htg_f - zone_siz_htg_f) / loop_siz_htg_f).abs > max_sizing_temp_delta
              check_elems << OpenStudio::Attribute.new('flag', "For #{zone.name}, the sizing for the air loop is done with a heating supply air temp of #{loop_siz_htg_f.round(2)}F, but the sizing for the zone is done with a heating supply air temp of #{zone_siz_htg_f.round(2)}F. These are farther apart than the acceptable #{(max_sizing_temp_delta * 100.0).round(2)}% difference.")
            end
          end
        end

        # Determine the min and max operational temperatures
        loop_op_min_f = nil
        loop_op_max_f = nil
        airloop.supplyOutletNode.setpointManagers.each do |spm|
          obj_type = spm.iddObjectType.valueName.to_s
          case obj_type
          when 'OS_SetpointManager_Scheduled'
            sch = spm.to_SetpointManagerScheduled.get.schedule
            if sch.to_ScheduleRuleset.is_initialized
              min_c = std.schedule_ruleset_annual_min_max_value(sch.to_ScheduleRuleset.get)['min']
              max_c = std.schedule_ruleset_annual_min_max_value(sch.to_ScheduleRuleset.get)['max']
            elsif sch.to_ScheduleConstant.is_initialized
              min_c = std.schedule_constant_annual_min_max_value(sch.to_ScheduleConstant.get)['min']
              max_c = std.schedule_constant_annual_min_max_value(sch.to_ScheduleConstant.get)['max']
            else
              next
            end
            loop_op_min_f = OpenStudio.convert(min_c, 'C', 'F').get
            loop_op_max_f = OpenStudio.convert(max_c, 'C', 'F').get
          when 'OS_SetpointManager_SingleZoneReheat'
            spm = spm.to_SetpointManagerSingleZoneReheat.get
            loop_op_min_f = OpenStudio.convert(spm.minimumSupplyAirTemperature, 'C', 'F').get
            loop_op_max_f = OpenStudio.convert(spm.maximumSupplyAirTemperature, 'C', 'F').get
          when 'OS_SetpointManager_Warmest'
            spm = spm.to_SetpointManagerSingleZoneReheat.get
            loop_op_min_f = OpenStudio.convert(spm.minimumSetpointTemperature, 'C', 'F').get
            loop_op_max_f = OpenStudio.convert(spm.maximumSetpointTemperature, 'C', 'F').get
          when 'OS_SetpointManager_WarmestTemperatureFlow'
            spm = spm.to_SetpointManagerSingleZoneReheat.get
            loop_op_min_f = OpenStudio.convert(spm.minimumSetpointTemperature, 'C', 'F').get
            loop_op_max_f = OpenStudio.convert(spm.maximumSetpointTemperature, 'C', 'F').get
          else
            next # Only check the commonly used setpoint managers
          end
        end

        # Compare air loop sizing temperatures to operational temperatures

        # Cooling
        if loop_op_min_f
          if ((loop_op_min_f - loop_siz_clg_f) / loop_op_min_f).abs > max_sizing_temp_delta
            check_elems << OpenStudio::Attribute.new('flag', "For #{airloop.name}, the sizing is done with a cooling supply air temp of #{loop_siz_clg_f.round(2)}F, but the setpoint manager controlling the loop operates down to #{loop_op_min_f.round(2)}F. These are farther apart than the acceptable #{(max_sizing_temp_delta * 100.0).round(2)}% difference.")
          end
        end

        # Heating
        if loop_op_max_f
          if ((loop_op_max_f - loop_siz_htg_f) / loop_op_max_f).abs > max_sizing_temp_delta
            check_elems << OpenStudio::Attribute.new('flag', "For #{airloop.name}, the sizing is done with a heating supply air temp of #{loop_siz_htg_f.round(2)}F, but the setpoint manager controlling the loop operates up to #{loop_op_max_f.round(2)}F. These are farther apart than the acceptable #{(max_sizing_temp_delta * 100.0).round(2)}% difference.")
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
