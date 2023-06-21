# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class SetThermostatSchedules_Test < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_SetThermostatSchedules
    # create an instance of the measure
    measure = SetThermostatSchedules.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make example model
    model = OpenStudio::Model.exampleModel

    model.getThermalZones.each do |zone|
      thermostatSetpointDualSetpoint = zone.thermostatSetpointDualSetpoint
      if thermostatSetpointDualSetpoint.is_initialized
        thermostatSetpointDualSetpoint.get.remove
      end
      zone.resetThermostatSetpointDualSetpoint
    end

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(4, arguments.size)
    assert_equal('zones', arguments[0].name)
    assert(arguments[0].hasDefaultValue)
    assert_equal('cooling_sch', arguments[1].name)
    assert(arguments[1].hasDefaultValue)
    assert_equal('heating_sch', arguments[2].name)
    assert(arguments[2].hasDefaultValue)
    assert_equal('material_cost', arguments[3].name)
    assert(arguments[3].hasDefaultValue)

    # set argument values to default values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    zones = arguments[0].clone
    assert(zones.setValue('*All Thermal Zones*'))
    argument_map['zones'] = zones

    cooling_sch = arguments[1].clone
    assert(cooling_sch.setValue('*No Change*'))
    argument_map['cooling_sch'] = cooling_sch

    heating_sch = arguments[2].clone
    assert(heating_sch.setValue('*No Change*'))
    argument_map['heating_sch'] = heating_sch

    material_cost = arguments[3].clone
    assert(material_cost.setValue(100.0))
    argument_map['material_cost'] = material_cost

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'NA')
    assert(result.warnings.empty?)
    assert(result.info.size == 1)

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    num_zones = 0
    model.getThermalZones.each do |zone|
      thermostatSetpointDualSetpoint = zone.thermostatSetpointDualSetpoint
      assert(thermostatSetpointDualSetpoint.empty?)
      num_zones += 1
    end
    assert_equal(1, num_zones)
    assert_equal(0, model.getLifeCycleCosts.size)

    new_sch = nil
    model.getScheduleRulesets.each do |sch|
      if !sch.scheduleTypeLimits.empty?
        if sch.scheduleTypeLimits.get.unitType == 'Temperature'
          new_sch = sch.clone(model).to_ScheduleRuleset.get
          break
        end
      end
    end
    assert(new_sch)
    assert(!new_sch.scheduleTypeLimits.empty?)
    assert_equal('Temperature', new_sch.scheduleTypeLimits.get.unitType)

    # set argument values to default values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    zones = arguments[0].clone
    assert(zones.setValue('*All Thermal Zones*'))
    argument_map['zones'] = zones

    cooling_sch = arguments[1].clone
    assert(cooling_sch.setValue(new_sch.handle.to_s))
    argument_map['cooling_sch'] = cooling_sch

    heating_sch = arguments[2].clone
    assert(heating_sch.setValue(new_sch.handle.to_s))
    argument_map['heating_sch'] = heating_sch

    material_cost = arguments[3].clone
    assert(material_cost.setValue(100.0))
    argument_map['material_cost'] = material_cost

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 1)

    num_zones = 0
    model.getThermalZones.each do |zone|
      thermostatSetpointDualSetpoint = zone.thermostatSetpointDualSetpoint
      if thermostatSetpointDualSetpoint.is_initialized
        heating = thermostatSetpointDualSetpoint.get.heatingSetpointTemperatureSchedule
        assert(heating.is_initialized)
        assert(heating.get.handle.to_s == new_sch.handle.to_s)
        cooling = thermostatSetpointDualSetpoint.get.coolingSetpointTemperatureSchedule
        assert(cooling.is_initialized)
        assert(cooling.get.handle.to_s == new_sch.handle.to_s)
        num_zones += 1
      end
    end
    assert_equal(1, num_zones)
    assert_equal(num_zones, model.getLifeCycleCosts.size)
  end
end
