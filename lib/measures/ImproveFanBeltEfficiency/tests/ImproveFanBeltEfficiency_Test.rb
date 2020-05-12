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

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class ImproveFanBeltEfficiency_Test < Minitest::Test
  def test_ImproveFanBeltEfficiency_single_air_loop
    # create an instance of the measure
    measure = ImproveFanBeltEfficiency.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(10, arguments.size)
    count = -1
    assert_equal('object', arguments[count += 1].name)
    assert_equal('motor_eff', arguments[count += 1].name)
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
    assert(object.setValue('Packaged Rooftop VAV with Reheat'))
    argument_map['object'] = object

    motor_eff = arguments[count += 1].clone
    assert(motor_eff.setValue(3))
    argument_map['motor_eff'] = motor_eff

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(false))
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

  def test_ImproveFanBeltEfficiency_single_plant_loop
    # create an instance of the measure
    measure = ImproveFanBeltEfficiency.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(10, arguments.size)
    count = -1
    assert_equal('object', arguments[count += 1].name)
    assert_equal('motor_eff', arguments[count += 1].name)
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

    motor_eff = arguments[count += 1].clone
    assert(motor_eff.setValue(7))
    argument_map['motor_eff'] = motor_eff

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(false))
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

  def test_ImproveFanBeltEfficiency_all_loops
    # create an instance of the measure
    measure = ImproveFanBeltEfficiency.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(10, arguments.size)
    count = -1
    assert_equal('object', arguments[count += 1].name)
    assert_equal('motor_eff', arguments[count += 1].name)
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

    motor_eff = arguments[count += 1].clone
    assert(motor_eff.setValue(-2))
    argument_map['motor_eff'] = motor_eff

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(false))
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
