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
  # Check the plant loop operational vs. sizing temperatures
  # and make sure everything is coordinated.  This identifies problems
  # caused by sizing to one set of conditions and operating at a different set.
  def check_plant_temps(category, target_standard, max_sizing_temp_delta = 0.1, name_only = false)
    # summary of the check
    check_elems = OpenStudio::AttributeVector.new
    check_elems << OpenStudio::Attribute.new('name', 'Plant Loop Temperatures')
    check_elems << OpenStudio::Attribute.new('category', category)
    check_elems << OpenStudio::Attribute.new('description', 'Check that plant loop sizing and operation temperatures are coordinated.')

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
      # Check each plant loop in the model
      @model.getPlantLoops.sort.each do |plant_loop|
        loop_name = plant_loop.name.to_s

        # Get the central heating and cooling SAT for sizing
        sizing_plant = plant_loop.sizingPlant
        loop_siz_f = OpenStudio.convert(sizing_plant.designLoopExitTemperature, 'C', 'F').get

        # Determine the min and max operational temperatures
        loop_op_min_f = nil
        loop_op_max_f = nil
        plant_loop.supplyOutletNode.setpointManagers.each do |spm|
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
          when 'OS_SetpointManager_Scheduled_DualSetpoint'
            spm = spm.to_SetpointManagerSingleZoneReheat.get
            # Lowest setpoint is minimum of low schedule
            low_sch = spm.to_SetpointManagerScheduled.get.lowSetpointSchedule
            next if low_sch.empty?
            low_sch = low_sch.get
            if low_sch.to_ScheduleRuleset.is_initialized
              min_c = std.schedule_ruleset_annual_min_max_value(low_sch.to_ScheduleRuleset.get)['min']
              max_c = std.schedule_ruleset_annual_min_max_value(low_sch.to_ScheduleRuleset.get)['max']
            elsif low_sch.to_ScheduleConstant.is_initialized
              min_c = std.schedule_constant_annual_min_max_value(low_sch.to_ScheduleConstant.get)['min']
              max_c = std.schedule_constant_annual_min_max_value(low_sch.to_ScheduleConstant.get)['max']
            else
              next
            end
            loop_op_min_f = OpenStudio.convert(min_c, 'C', 'F').get
            # Highest setpoint it maximum of high schedule
            high_sch = spm.to_SetpointManagerScheduled.get.highSetpointSchedule
            next if high_sch.empty?
            high_sch = high_sch.get
            if high_sch.to_ScheduleRuleset.is_initialized
              min_c = std.schedule_ruleset_annual_min_max_value(high_sch.to_ScheduleRuleset.get)['min']
              max_c = std.schedule_ruleset_annual_min_max_value(high_sch.to_ScheduleRuleset.get)['max']
            elsif high_sch.to_ScheduleConstant.is_initialized
              min_c = std.schedule_constant_annual_min_max_value(high_sch.to_ScheduleConstant.get)['min']
              max_c = std.schedule_constant_annual_min_max_value(high_sch.to_ScheduleConstant.get)['max']
            else
              next
            end
            loop_op_max_f = OpenStudio.convert(max_c, 'C', 'F').get
          when 'OS_SetpointManager_OutdoorAirReset'
            spm = spm.to_SetpointManagerOutdoorAirReset.get
            temp_1_f = OpenStudio.convert(spm.setpointatOutdoorHighTemperature, 'C', 'F').get
            temp_2_f = OpenStudio.convert(spm.setpointatOutdoorLowTemperature, 'C', 'F').get
            loop_op_min_f = [temp_1_f, temp_2_f].min
            loop_op_max_f = [temp_1_f, temp_2_f].max
          else
            next # Only check the commonly used setpoint managers
          end
        end

        # Compare plant loop sizing temperatures to operational temperatures
        case sizing_plant.loopType
        when 'Heating'
          if loop_op_max_f
            if ((loop_op_max_f - loop_siz_f) / loop_op_max_f).abs > max_sizing_temp_delta
              check_elems << OpenStudio::Attribute.new('flag', "For #{plant_loop.name}, the sizing is done with a supply water temp of #{loop_siz_f.round(2)}F, but the setpoint manager controlling the loop operates up to #{loop_op_max_f.round(2)}F. These are farther apart than the acceptable #{(max_sizing_temp_delta * 100.0).round(2)}% difference.")
            end
          end
        when 'Cooling'
          if loop_op_min_f
            if ((loop_op_min_f - loop_siz_f) / loop_op_min_f).abs > max_sizing_temp_delta
              check_elems << OpenStudio::Attribute.new('flag', "For #{plant_loop.name}, the sizing is done with a supply water temp of #{loop_siz_f.round(2)}F, but the setpoint manager controlling the loop operates down to #{loop_op_min_f.round(2)}F. These are farther apart than the acceptable #{(max_sizing_temp_delta * 100.0).round(2)}% difference.")
            end
          end
        when 'Condenser'
          # Not checking sizing of condenser loops
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
