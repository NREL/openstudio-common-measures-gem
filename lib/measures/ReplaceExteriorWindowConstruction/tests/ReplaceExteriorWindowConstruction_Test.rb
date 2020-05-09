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

class ReplaceExteriorWindowConstruction_Test < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_ReplaceExteriorWindowConstruction
    # create an instance of the measure
    measure = ReplaceExteriorWindowConstruction.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(11, arguments.size)
    assert_equal('construction', arguments[0].name)
    assert(!arguments[0].hasDefaultValue)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    construction = arguments[0].clone
    assert(!construction.setValue('000_Exterior Window'))
    argument_map['construction'] = construction
    measure.run(model, runner, argument_map)
    result = runner.result

    assert(result.value.valueName == 'Fail')
  end

  def test_ReplaceExteriorWindowConstruction_new_construction_FullyCosted
    # create an instance of the measure
    measure = ReplaceExteriorWindowConstruction.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal('construction', arguments[0].name)
    assert(!arguments[0].hasDefaultValue)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    construction = arguments[count += 1].clone
    assert(construction.setValue('000_Exterior Window'))
    argument_map['construction'] = construction

    change_fixed_windows = arguments[count += 1].clone
    assert(change_fixed_windows.setValue(true))
    argument_map['change_fixed_windows'] = change_fixed_windows

    change_operable_windows = arguments[count += 1].clone
    assert(change_operable_windows.setValue(false))
    argument_map['change_operable_windows'] = change_operable_windows

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(true))
    argument_map['remove_costs'] = remove_costs

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(5.0))
    argument_map['material_cost_ip'] = material_cost_ip

    demolition_cost_ip = arguments[count += 1].clone
    assert(demolition_cost_ip.setValue(1.0))
    argument_map['demolition_cost_ip'] = demolition_cost_ip

    years_until_costs_start = arguments[count += 1].clone
    assert(years_until_costs_start.setValue(0))
    argument_map['years_until_costs_start'] = years_until_costs_start

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map['expected_life'] = expected_life

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0.25))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    end

  def test_ReplaceExteriorWindowConstruction_retrofit_FullyCosted
    # create an instance of the measure
    measure = ReplaceExteriorWindowConstruction.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01Costed.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(11, arguments.size)
    assert_equal('construction', arguments[0].name)
    assert(!arguments[0].hasDefaultValue)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    construction = arguments[count += 1].clone
    assert(construction.setValue('000_Exterior Window'))
    argument_map['construction'] = construction

    change_fixed_windows = arguments[count += 1].clone
    assert(change_fixed_windows.setValue(true))
    argument_map['change_fixed_windows'] = change_fixed_windows

    change_operable_windows = arguments[count += 1].clone
    assert(change_operable_windows.setValue(false))
    argument_map['change_operable_windows'] = change_operable_windows

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(true))
    argument_map['remove_costs'] = remove_costs

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(5.0))
    argument_map['material_cost_ip'] = material_cost_ip

    demolition_cost_ip = arguments[count += 1].clone
    assert(demolition_cost_ip.setValue(1.0))
    argument_map['demolition_cost_ip'] = demolition_cost_ip

    years_until_costs_start = arguments[count += 1].clone
    assert(years_until_costs_start.setValue(3))
    argument_map['years_until_costs_start'] = years_until_costs_start

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(true))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map['expected_life'] = expected_life

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0.25))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
  end

  def test_ReplaceExteriorWindowConstruction_retrofit_MinimalCost
    # create an instance of the measure
    measure = ReplaceExteriorWindowConstruction.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(11, arguments.size)
    assert_equal('construction', arguments[0].name)
    assert(!arguments[0].hasDefaultValue)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    construction = arguments[count += 1].clone
    assert(construction.setValue('000_Exterior Window'))
    argument_map['construction'] = construction

    change_fixed_windows = arguments[count += 1].clone
    assert(change_fixed_windows.setValue(true))
    argument_map['change_fixed_windows'] = change_fixed_windows

    change_operable_windows = arguments[count += 1].clone
    assert(change_operable_windows.setValue(false))
    argument_map['change_operable_windows'] = change_operable_windows

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(true))
    argument_map['remove_costs'] = remove_costs

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(5.0))
    argument_map['material_cost_ip'] = material_cost_ip

    demolition_cost_ip = arguments[count += 1].clone
    assert(demolition_cost_ip.setValue(0))
    argument_map['demolition_cost_ip'] = demolition_cost_ip

    years_until_costs_start = arguments[count += 1].clone
    assert(years_until_costs_start.setValue(0))
    argument_map['years_until_costs_start'] = years_until_costs_start

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map['expected_life'] = expected_life

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
  end

  def test_ReplaceExteriorWindowConstruction_retrofit_NoCost
    # create an instance of the measure
    measure = ReplaceExteriorWindowConstruction.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(11, arguments.size)
    assert_equal('construction', arguments[0].name)
    assert(!arguments[0].hasDefaultValue)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    construction = arguments[count += 1].clone
    assert(construction.setValue('000_Exterior Window'))
    argument_map['construction'] = construction

    change_fixed_windows = arguments[count += 1].clone
    assert(change_fixed_windows.setValue(true))
    argument_map['change_fixed_windows'] = change_fixed_windows

    change_operable_windows = arguments[count += 1].clone
    assert(change_operable_windows.setValue(false))
    argument_map['change_operable_windows'] = change_operable_windows

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(true))
    argument_map['remove_costs'] = remove_costs

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(0))
    argument_map['material_cost_ip'] = material_cost_ip

    demolition_cost_ip = arguments[count += 1].clone
    assert(demolition_cost_ip.setValue(0))
    argument_map['demolition_cost_ip'] = demolition_cost_ip

    years_until_costs_start = arguments[count += 1].clone
    assert(years_until_costs_start.setValue(0))
    argument_map['years_until_costs_start'] = years_until_costs_start

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map['expected_life'] = expected_life

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
  end

  def test_ReplaceExteriorWindowConstruction_ReverseTranslatedModel
    # create an instance of the measure
    measure = ReplaceExteriorWindowConstruction.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/ReverseTranslatedModel.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(11, arguments.size)
    assert_equal('construction', arguments[0].name)
    assert(!arguments[0].hasDefaultValue)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    construction = arguments[count += 1].clone
    assert(construction.setValue('Window Non-res Fixed'))
    argument_map['construction'] = construction

    change_fixed_windows = arguments[count += 1].clone
    assert(change_fixed_windows.setValue(true))
    argument_map['change_fixed_windows'] = change_fixed_windows

    change_operable_windows = arguments[count += 1].clone
    assert(change_operable_windows.setValue(false))
    argument_map['change_operable_windows'] = change_operable_windows

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(true))
    argument_map['remove_costs'] = remove_costs

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(0))
    argument_map['material_cost_ip'] = material_cost_ip

    demolition_cost_ip = arguments[count += 1].clone
    assert(demolition_cost_ip.setValue(0))
    argument_map['demolition_cost_ip'] = demolition_cost_ip

    years_until_costs_start = arguments[count += 1].clone
    assert(years_until_costs_start.setValue(0))
    argument_map['years_until_costs_start'] = years_until_costs_start

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map['expected_life'] = expected_life

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
  end

  def test_ReplaceExteriorWindowConstruction_EmptySpaceNoLoadsOrSurfaces
    # create an instance of the measure
    measure = ReplaceExteriorWindowConstruction.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # add a space to the model without any geometry or loads, want to make sure measure works or fails gracefully
    new_space = OpenStudio::Model::Space.new(model)

    # make simple glazing material and then a construction to use it
    window_mat = OpenStudio::Model::SimpleGlazing.new(model)
    window_const = OpenStudio::Model::Construction.new(model)
    window_const.insertLayer(0, window_mat)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(11, arguments.size)
    assert_equal('construction', arguments[0].name)
    assert(!arguments[0].hasDefaultValue)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    construction = arguments[count += 1].clone
    assert(construction.setValue(window_const.name.to_s))
    argument_map['construction'] = construction

    change_fixed_windows = arguments[count += 1].clone
    assert(change_fixed_windows.setValue(true))
    argument_map['change_fixed_windows'] = change_fixed_windows

    change_operable_windows = arguments[count += 1].clone
    assert(change_operable_windows.setValue(false))
    argument_map['change_operable_windows'] = change_operable_windows

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(true))
    argument_map['remove_costs'] = remove_costs

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(0))
    argument_map['material_cost_ip'] = material_cost_ip

    demolition_cost_ip = arguments[count += 1].clone
    assert(demolition_cost_ip.setValue(0))
    argument_map['demolition_cost_ip'] = demolition_cost_ip

    years_until_costs_start = arguments[count += 1].clone
    assert(years_until_costs_start.setValue(0))
    argument_map['years_until_costs_start'] = years_until_costs_start

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map['expected_life'] = expected_life

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'NA')
  end
end
