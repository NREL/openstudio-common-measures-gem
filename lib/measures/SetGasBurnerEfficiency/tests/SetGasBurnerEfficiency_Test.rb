# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class SetGasBurnerEfficiency_Test < Minitest::Test
  def test_SetGasBurnerEfficiency_single_loop
    # create an instance of the measure
    measure = SetGasBurnerEfficiency.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(10, arguments.size)
    count = -1
    assert_equal('object', arguments[count += 1].name)
    assert_equal('eff', arguments[count += 1].name)
    assert_equal('remove_costs', arguments[count += 1].name)
    assert_equal('material_cost', arguments[count += 1].name)
    assert_equal('demolition_cost', arguments[count += 1].name)
    assert_equal('years_until_costs_start', arguments[count += 1].name)
    assert_equal('demo_cost_initial_const', arguments[count += 1].name)
    assert_equal('expected_life', arguments[count += 1].name)
    assert_equal('om_cost', arguments[count += 1].name)
    assert_equal('om_frequency', arguments[count += 1].name)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/0320_ModelWithHVAC_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    object = arguments[count += 1].clone
    assert(object.setValue('Packaged Rooftop Air Conditioner'))
    argument_map['object'] = object

    eff = arguments[count += 1].clone
    assert(eff.setValue(0.9))
    argument_map['eff'] = eff

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(true))
    argument_map['remove_costs'] = remove_costs

    material_cost = arguments[count += 1].clone
    assert(material_cost.setValue(5.0))
    argument_map['material_cost'] = material_cost

    demolition_cost = arguments[count += 1].clone
    assert(demolition_cost.setValue(1.0))
    argument_map['demolition_cost'] = demolition_cost

    years_until_costs_start = arguments[count += 1].clone
    assert(years_until_costs_start.setValue(0))
    argument_map['years_until_costs_start'] = years_until_costs_start

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map['expected_life'] = expected_life

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.25))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 2)
    # assert(result.info.size == 1)
  end

  def test_SetGasBurnerEfficiency_all_loop
    # create an instance of the measure
    measure = SetGasBurnerEfficiency.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(10, arguments.size)
    count = -1
    assert_equal('object', arguments[count += 1].name)
    assert_equal('eff', arguments[count += 1].name)
    assert_equal('remove_costs', arguments[count += 1].name)
    assert_equal('material_cost', arguments[count += 1].name)
    assert_equal('demolition_cost', arguments[count += 1].name)
    assert_equal('years_until_costs_start', arguments[count += 1].name)
    assert_equal('demo_cost_initial_const', arguments[count += 1].name)
    assert_equal('expected_life', arguments[count += 1].name)
    assert_equal('om_cost', arguments[count += 1].name)
    assert_equal('om_frequency', arguments[count += 1].name)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/0320_ModelWithHVAC_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    object = arguments[count += 1].clone
    assert(object.setValue('*All Air Loops*'))
    argument_map['object'] = object

    eff = arguments[count += 1].clone
    assert(eff.setValue(0.9))
    argument_map['eff'] = eff

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(true))
    argument_map['remove_costs'] = remove_costs

    material_cost = arguments[count += 1].clone
    assert(material_cost.setValue(5.0))
    argument_map['material_cost'] = material_cost

    demolition_cost = arguments[count += 1].clone
    assert(demolition_cost.setValue(1.0))
    argument_map['demolition_cost'] = demolition_cost

    years_until_costs_start = arguments[count += 1].clone
    assert(years_until_costs_start.setValue(0))
    argument_map['years_until_costs_start'] = years_until_costs_start

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map['expected_life'] = expected_life

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.25))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 2)
    # assert(result.info.size == 1)
  end
end
