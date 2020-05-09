
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

# require 'openstudio'
# require 'openstudio/measure/ShowRunnerOutput'
# require 'fileutils'
#
# require_relative '../measure.rb'
# require 'minitest/autorun'
#
# In order to test without having to run energyplus, we mock out some of the methods called by
# the measure. We give ourselves the ability to insert arbitrary time series by storing
# series in the $serieses global variable. Instead of loading series data from from
# the sql file, our measure will get data from the $serieses entry with the key matching
# the name that was requested.
# $serieses = {}
#
# class OpenStudio::SqlFile
#   def timeSeries(envperiod, rate, name, index)
#     return $serieses["#{name}|#{index}"] || OpenStudio::TimeSeries.new
#   end
# end
#
# class OpenStudio::TimeSeries
#   def get
#     self
#   end
#
#   def empty?
#     false
#   end
# end
#
# class Array
#   def to_vector
#     v = OpenStudio::Vector.new(size)
#     each_with_index { |o, i| v[i] = o }
#     return v
#   end
# end
#
# class UnmetLoadHoursTroubleshooting_Test < Minitest::Test
#   def sqlPath
#     return "#{File.dirname(__FILE__)}/sqlfile.sql"
#     # return "#{File.dirname(__FILE__)}/ExampleModel/ModelToIdf/EnergyPlusPreProcess-0/EnergyPlus-0/eplusout.sql"
#   end
#
#   # create test files if they do not exist
#   def setup
#     @targetName = '2zone'
#     # targetName = "undersizedHVAC"
#     # targetName = "ExampleModel"
#
#     # create an instance of the measure
#     @measure = UnmetLoadHoursTroubleshooting.new
#
#     # create an instance of the runner
#     @runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
#
#     # Make an empty model
#     @model = OpenStudio::Model::Model.new
#     @runner.setLastOpenStudioModel(@model)
#
#     # get arguments
#     @arguments = @measure.arguments
#
#     # make argument map
#     make_argument_map
#
#     # Create a fake sql file - our measure will crash if @runner has no sql file set.
#     # We don't get data from this file because we get data from our patched SqlFile class instead (see above)
#     #   sqlFile = OpenStudio::SqlFile.new(OpenStudio::Path.new(sqlPath))
#     @runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sqlPath))
#     #   $serieses["Zone Mechanical Ventilation Mass Flow Rate|ZONE1"] = OpenStudio::TimeSeries.new(OpenStudio::Date.new, OpenStudio::Time.new(1.0), (0..364).to_a.to_vector, "m^3/s")
#   end
#
#   # When there are no thermal zones this measure is not applicable
#   def test_NoThermalZones
#     #skip "Broken in 2.5.1, address immediately"
#
#     @measure.run(@runner, @argument_map)
#     result = @runner.result
#     assert_equal OpenStudio::Measure::OSResultValue.new(-1), result.value
#   end
#
#   def make_main_and_slave_zone(zoneSettings)
#     mainZone = OpenStudio::Model::ThermalZone.new(@model)
#     mainZone.setName('Main Zone')
#     slaveZone = OpenStudio::Model::ThermalZone.new(@model)
#     slaveZone.setName('Slave Zone')
#
#     # We should put in 8760 data points, but the tests run much faster with only 100 and for this measure we can get away with fewer data points
#     mainZoneAirTemperature = Array.new(100) { |i| zoneSettings[:mainZoneAirTemperature] || 25 }
#     slaveZoneAirTemperature = Array.new(100) { |i| zoneSettings[:slaveZoneAirTemperature] || 25 }
#     zoneHeatingSetpoint = Array.new(100) { |i| zoneSettings[:zoneHeatingSetpoint] || 25 }
#     zoneCoolingSetpoint = Array.new(100) { |i| zoneSettings[:zoneCoolingSetpoint] || 28 }
#     zoneOccupancy = Array.new(100) { |i| zoneSettings[:occupancy] || 2 }
#
#     oneHour = 0.0416666
#
#     $serieses['Zone Mean Air Temperature|MAIN ZONE'] = OpenStudio::TimeSeries.new(OpenStudio::Date.new, OpenStudio::Time.new(oneHour), mainZoneAirTemperature.to_vector, 'C')
#     $serieses['Zone Mean Air Temperature|SLAVE ZONE'] = OpenStudio::TimeSeries.new(OpenStudio::Date.new, OpenStudio::Time.new(oneHour), slaveZoneAirTemperature.to_vector, 'C')
#     $serieses['Zone Thermostat Heating Setpoint Temperature|MAIN ZONE'] = OpenStudio::TimeSeries.new(OpenStudio::Date.new, OpenStudio::Time.new(oneHour), zoneHeatingSetpoint.to_vector, 'C')
#     $serieses['Zone Thermostat Heating Setpoint Temperature|SLAVE ZONE'] = OpenStudio::TimeSeries.new(OpenStudio::Date.new, OpenStudio::Time.new(oneHour), zoneHeatingSetpoint.to_vector, 'C')
#     $serieses['Zone Thermostat Cooling Setpoint Temperature|MAIN ZONE'] = OpenStudio::TimeSeries.new(OpenStudio::Date.new, OpenStudio::Time.new(oneHour), zoneCoolingSetpoint.to_vector, 'C')
#     $serieses['Zone Thermostat Cooling Setpoint Temperature|SLAVE ZONE'] = OpenStudio::TimeSeries.new(OpenStudio::Date.new, OpenStudio::Time.new(oneHour), zoneCoolingSetpoint.to_vector, 'C')
#     $serieses['Zone People Occupant Count|MAIN ZONE'] = OpenStudio::TimeSeries.new(OpenStudio::Date.new, OpenStudio::Time.new(oneHour), zoneOccupancy.to_vector, 'people')
#     $serieses['Zone People Occupant Count|SLAVE ZONE'] = OpenStudio::TimeSeries.new(OpenStudio::Date.new, OpenStudio::Time.new(oneHour), zoneOccupancy.to_vector, 'people')
#
#     return mainZone, slaveZone
#   end
#
#   def make_air_loop(loopSettings)
#     loop = OpenStudio::Model::AirLoopHVAC.new(@model)
#     loop.setName('HVAC Air Loop')
#     loop.sizingSystem.setCentralHeatingDesignSupplyAirTemperature(loopSettings[:heatingDesignTemp] || 25)
#     loop.sizingSystem.setCentralCoolingDesignSupplyAirTemperature(loopSettings[:coolingDesignTemp] || 25)
#     schedule = build_monthly_schedule { |m, h| m * 2 + h / 24.0 }  # Maximum scheduled value is 2*12+1 = 25 degrees C
#     schedule.setName('Air Loop Setpoint Schedule')
#     # Create a setpoint manager for the loop
#     manager = OpenStudio::Model::SetpointManagerScheduled.new(@model, schedule)
#     manager.addToNode(loop.supplyOutletNode)
#     return loop
#   end
#
#   def make_plant_loop(loopSettings)
#     loop = OpenStudio::Model::PlantLoop.new(@model)
#     loop.setName('Plant Loop')
#     loop.sizingPlant.setDesignLoopExitTemperature(loopSettings[:designTemp] || 19)
#     schedule = build_monthly_schedule { |m, h| m * 2 + h / 24.0 }  # Maximum scheduled value is 2*12+1 = 25 degrees C
#     schedule.setName('Plant Loop Setpoint Schedule')
#     # Create a setpoint manager for the loop
#     manager = OpenStudio::Model::SetpointManagerScheduled.new(@model, schedule)
#     manager.addToNode(loop.supplyOutletNode)
#     return loop
#   end
#
#   # Takes a block of the form { |m, h| schedule_value(m, h) } where m represents the month and h the hour of a day in that month.
#   def build_monthly_schedule
#     sch = OpenStudio::Model::ScheduleRuleset.new(@model)
#     (1..12).to_a.each do |m|
#       day_sch = OpenStudio::Model::ScheduleDay.new(@model)
#       (1..24).to_a.each do |h|
#         day_sch.addValue(OpenStudio::Time.new(0, h, 0, 0), yield(m, h))
#       end
#       rule = OpenStudio::Model::ScheduleRule.new(sch, day_sch)
#       rule.setApplySunday(true)
#       rule.setApplyMonday(true)
#       rule.setApplyTuesday(true)
#       rule.setApplyWednesday(true)
#       rule.setApplyThursday(true)
#       rule.setApplyFriday(true)
#       rule.setApplySaturday(true)
#       rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(m), 1))
#     end
#     return sch
#   end
#
#   def test_UnmetHeatingHours
#     #skip "Broken in 2.5.1, address immediately"
#
#     make_main_and_slave_zone(slaveZoneAirTemperature: 23)
#
#     @measure.run(@runner, @argument_map)
#     result = @runner.result
#     assert_equal OpenStudio::Measure::OSResultValue.new(0), result.value
#
#     mainZoneMetrics = @measure.measureMetrics[:zone_collection].find { |z| z[:name] == 'Main Zone' }
#     slaveZoneMetrics = @measure.measureMetrics[:zone_collection].find { |z| z[:name] == 'Slave Zone' }
#
#     assert_equal 100, slaveZoneMetrics[:unmet_heating_hrs], 'Slave zone unmet heating hours were not as expected'
#     assert_equal 0, mainZoneMetrics[:unmet_heating_hrs], 'Main zone unmet heating hours were not as expected'
#   end
#
#   def test_AirLoopSetpointVsDesignTemp
#     #skip "Broken in 2.5.1, address immediately"
#
#     make_main_and_slave_zone({})
#     make_air_loop(heatingDesignTemp: 26) # Max setpoint temp is 25
#
#     @measure.run(@runner, @argument_map)
#     result = @runner.result
#     assert_equal OpenStudio::Measure::OSResultValue.new(0), result.value
#
#     airLoopData = @measure.measureMetrics[:air_loop_vs_schedule_temp]['HVAC Air Loop']
#
#     assert_not_equal :no_scheduled_manager, airLoopData[:status], 'Air loop status'
#     assert_equal :failed, airLoopData[:heating_status], 'Air loop heating status'
#   end
#
#   def test_AirLoopReasonableDesignTemps
#     #skip "Broken in 2.5.1, address immediately"
#
#     make_main_and_slave_zone({})
#     make_air_loop(heatingDesignTemp: 32.2, coolingDesignTemp: 18.3) # < 90 degF heaging and > 65 degF cooling
#
#     @measure.run(@runner, @argument_map)
#     result = @runner.result
#     assert_equal OpenStudio::Measure::OSResultValue.new(0), result.value
#
#     airLoopData = @measure.measureMetrics[:airloop_reasonable_setting]['HVAC Air Loop']
#
#     assert_in_delta 90, airLoopData[:centralHeatingTempF], 1
#     assert_in_delta 65, airLoopData[:centralCoolingTempF], 1
#   end
#
#   def test_PlantLoopSetpointVsDesignTemp
#     #skip "Broken in 2.5.1, address immediately"
#
#     make_main_and_slave_zone({})
#     loop = make_plant_loop(designTemp: 23) # Max setpoint temp is 25
#
#     @measure.run(@runner, @argument_map)
#     result = @runner.result
#     assert_equal OpenStudio::Measure::OSResultValue.new(0), result.value
#
#     plantLoopData = @measure.measureMetrics[:plant_loop_temp_vs_setpoints]['Plant Loop']
#
#     assert_not_equal :no_plant_loops, @measure.measureMetrics[:test_six_state]
#     assert_equal :failed, plantLoopData[:state], 'Plant loop status'
#     assert_equal 'Heating', plantLoopData[:loop_type], 'Plant loop type'
#   end
#
#   def test_buildingWithNoProblems
#     #skip "Broken in 2.5.1, address immediately"
#
#     make_main_and_slave_zone({})
#     make_plant_loop({})
#     make_air_loop({})
#
#     @measure.run(@runner, @argument_map)
#     result = @runner.result
#     assert_equal OpenStudio::Measure::OSResultValue.new(0), result.value
#
#     plantLoopData = @measure.measureMetrics[:plant_loop_temp_vs_setpoints]['Plant Loop']
#     airLoopData = @measure.measureMetrics[:airloop_reasonable_setting]['HVAC Air Loop']
#
#     assert_not_equal :no_plant_loops, @measure.measureMetrics[:test_six_state]
#     assert_not_equal :no_scheduled_manager, airLoopData[:status], 'Air loop status'
#
#     assert_equal :passed, plantLoopData[:state], 'Plant loop status'
#     assert_not_equal :failed, airLoopData[:heating_status], 'Air loop heating status'
#   end
#
#   def make_argument_map
#     argMap = {
#       'measure_zone' => 'All Zones'
#     }
#     @argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(@arguments)
#     argMap.each { |key, value| set_argument(key, value) }
#   end
#
#   def set_argument(key, value)
#     arg = @arguments.find { |a| a.name == key }
#     refute_nil arg, "Expected to find argument of name #{key}, but didn't."
#
#     newArg = arg.clone
#     assert(newArg.setValue(value), "Could not set argument #{key} to #{value}")
#     @argument_map[key] = newArg
#   end
# end
