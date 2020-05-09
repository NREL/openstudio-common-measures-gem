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

class IncreaseInsulationRValueForExteriorWalls_Test < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_IncreaseInsulationRValueForExteriorWalls_01_bad
    # create an instance of the measure
    measure = IncreaseInsulationRValueForExteriorWalls.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(5, arguments.size)
    assert_equal('r_value', arguments[0].name)
    assert_equal(13.0, arguments[0].defaultValueAsDouble)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    r_value = arguments[0].clone
    assert(r_value.setValue(9000.0))
    argument_map['r_value'] = r_value
    measure.run(model, runner, argument_map)
    result = runner.result

    assert(result.value.valueName == 'Fail')
  end

  def test_IncreaseInsulationRValueForExteriorWalls_NewConstruction_FullyCosted
    # create an instance of the measure
    measure = IncreaseInsulationRValueForExteriorWalls.new

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

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set all argument values

    count = -1

    r_value = arguments[count += 1].clone
    assert(r_value.setValue(50.0))
    argument_map['r_value'] = r_value

    allow_reduction = arguments[count += 1].clone
    assert(allow_reduction.setValue('false'))
    argument_map['allow_reduction'] = allow_reduction

    material_cost_increase_ip = arguments[count += 1].clone
    assert(material_cost_increase_ip.setValue(2.0))
    argument_map['material_cost_increase_ip'] = material_cost_increase_ip

    one_time_retrofit_cost_ip = arguments[count += 1].clone
    assert(one_time_retrofit_cost_ip.setValue(0.0))
    argument_map['one_time_retrofit_cost_ip'] = one_time_retrofit_cost_ip

    years_until_retrofit_cost = arguments[count += 1].clone
    assert(years_until_retrofit_cost.setValue(0))
    argument_map['years_until_retrofit_cost'] = years_until_retrofit_cost

    # test initial model conditions
    surface1_found = false
    surface2_found = false
    model.getSurfaces.each do |surface|
      if surface.name.get == 'Surface 20'
        surface1_found = true
        construction = surface.construction # should use "ASHRAE_189.1-2009_ExtWall_Mass_ClimateZone_alt-res 5"
        assert(!construction.empty?)
        construction = construction.get.to_Construction
        assert(!construction.empty?)
        assert(construction.get.layers.size == 4)
        assert(construction.get.layers[2].name.get == 'Wall Insulation [42]')
        assert(construction.get.layers[2].thickness == 0.091400)

      elsif surface.name.get == 'Surface 14'
        # this is the one that doesnt get changed
        surface2_found = true
        construction = surface.construction # should use "Test_No Insulation"
        assert(!construction.empty?)
        construction = construction.get.to_Construction
        assert(!construction.empty?)
        assert(construction.get.layers.size == 3)
        assert(construction.get.layers[0].name.get == '000_M01 100mm brick')
        assert(construction.get.layers[1].name.get == '8IN CONCRETE HW_RefBldg')
        assert(construction.get.layers[2].name.get == '1/2IN Gypsum')
      end
    end
    assert(surface1_found)
    assert(surface2_found)

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result) #this displays the output when you run the test
    assert(result.value.valueName == 'Success')
    assert(result.info.size == 9)
    assert(result.warnings.size == 2)

    # test final model conditions
    surface1_found = false
    surface2_found = false
    model.getSurfaces.each do |surface|
      if surface.name.get == 'Surface 20'
        surface1_found = true
        construction = surface.construction # ASHRAE_189.1-2009_ExtWall_Mass_ClimateZone_alt-res 5 adj ext wall insulation"
        assert(!construction.empty?)
        construction = construction.get.to_Construction
        assert(!construction.empty?)
        assert(construction.get.layers.size == 4)
        assert(construction.get.layers[2].name.get == 'Wall Insulation [42]_R-value 50.0 (ft^2*h*R/Btu)')
        assert_in_delta(0.380398, construction.get.layers[2].thickness, 0.000001) # added for precision error
        # final model should have one construction cost line items associated with the construction (would be two if a retrofit project)
        # construction_cclis = construction.get.componentCostLineItems
        # assert(construction_cclis.size == 1)
        # check values and cost type of first object
        # ccli = construction_cclis[0]
        # assert(ccli.materialCostUnits.get == "CostPerArea")
        # assert_in_delta(269.1, ccli.materialCost.get, 0.1) #added for precision error

      elsif surface.name.get == 'Surface 14'
        # this is the one that doesnt get changed
        surface2_found = true
        construction = surface.construction # should use "Test_No Insulation"
        assert(!construction.empty?)
        construction = construction.get.to_Construction
        assert(!construction.empty?)
        assert(construction.get.layers.size == 3)
        assert(construction.get.layers[0].name.get == '000_M01 100mm brick')
        assert(construction.get.layers[1].name.get == '8IN CONCRETE HW_RefBldg')
        assert(construction.get.layers[2].name.get == '1/2IN Gypsum')
      end
    end
    assert(surface1_found)
    assert(surface2_found)

    # test messages
    assert(!result.finalCondition.empty?)
    assert(/applied to 1,077 \(ft\^2\)/.match(result.finalCondition.get.logMessage))

    # loop over info warnings

    # loop over warnings
    expected_messages = {}
    expected_messages[/The requested wall insulation R-value of 50\.0 ft\^2\*h\*R\/Btu is abnormally high./] = false
    expected_messages["Construction 'Test_No Insulation' does not appear to have an insulation layer and was not altered."] = false
    result.warnings.each do |warning|
      expected_messages.each_key do |message|
        if Regexp.new(message).match?(warning.logMessage)
          assert(expected_messages[message] == false, "Message '#{message}' found multiple times")
          expected_messages[message] = true
        end
      end
    end

    expected_messages.each_pair do |message, found|
      assert(found, "Message '#{message}' not found")
    end
  end

  def test_IncreaseInsulationRValueForExteriorWalls_Retrofit_FullyCosted
    # create an instance of the measure
    measure = IncreaseInsulationRValueForExteriorWalls.new

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

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set all argument values

    count = -1

    r_value = arguments[count += 1].clone
    assert(r_value.setValue(50.0))
    argument_map['r_value'] = r_value

    allow_reduction = arguments[count += 1].clone
    assert(allow_reduction.setValue('false'))
    argument_map['allow_reduction'] = allow_reduction

    material_cost_increase_ip = arguments[count += 1].clone
    assert(material_cost_increase_ip.setValue(2.0))
    argument_map['material_cost_increase_ip'] = material_cost_increase_ip

    one_time_retrofit_cost_ip = arguments[count += 1].clone
    assert(one_time_retrofit_cost_ip.setValue(3.5))
    argument_map['one_time_retrofit_cost_ip'] = one_time_retrofit_cost_ip

    years_until_retrofit_cost = arguments[count += 1].clone
    assert(years_until_retrofit_cost.setValue(0))
    argument_map['years_until_retrofit_cost'] = years_until_retrofit_cost

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result) #this displays the output when you run the test
    assert(result.value.valueName == 'Success')
    assert(result.info.size == 14)
    assert(result.warnings.size == 2)
  end

  def test_IncreaseInsulationRValueForExteriorWalls_Retrofit_NoCost
    # create an instance of the measure
    measure = IncreaseInsulationRValueForExteriorWalls.new

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

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set all argument values

    count = -1

    r_value = arguments[count += 1].clone
    assert(r_value.setValue(50.0))
    argument_map['r_value'] = r_value

    allow_reduction = arguments[count += 1].clone
    assert(allow_reduction.setValue('false'))
    argument_map['allow_reduction'] = allow_reduction

    material_cost_increase_ip = arguments[count += 1].clone
    assert(material_cost_increase_ip.setValue(0.0))
    argument_map['material_cost_increase_ip'] = material_cost_increase_ip

    one_time_retrofit_cost_ip = arguments[count += 1].clone
    assert(one_time_retrofit_cost_ip.setValue(0.0))
    argument_map['one_time_retrofit_cost_ip'] = one_time_retrofit_cost_ip

    years_until_retrofit_cost = arguments[count += 1].clone
    assert(years_until_retrofit_cost.setValue(0))
    argument_map['years_until_retrofit_cost'] = years_until_retrofit_cost

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result) #this displays the output when you run the test
    assert(result.value.valueName == 'Success')
    assert(result.info.size == 4)
    assert(result.warnings.size == 2)
  end

  def test_IncreaseInsulationRValueForExteriorWalls_ReverseTranslatedModel
    # create an instance of the measure
    measure = IncreaseInsulationRValueForExteriorWalls.new

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

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set all argument values

    count = -1

    r_value = arguments[count += 1].clone
    assert(r_value.setValue(50.0))
    argument_map['r_value'] = r_value

    allow_reduction = arguments[count += 1].clone
    assert(allow_reduction.setValue('false'))
    argument_map['allow_reduction'] = allow_reduction

    material_cost_increase_ip = arguments[count += 1].clone
    assert(material_cost_increase_ip.setValue(0.0))
    argument_map['material_cost_increase_ip'] = material_cost_increase_ip

    one_time_retrofit_cost_ip = arguments[count += 1].clone
    assert(one_time_retrofit_cost_ip.setValue(0.0))
    argument_map['one_time_retrofit_cost_ip'] = one_time_retrofit_cost_ip

    years_until_retrofit_cost = arguments[count += 1].clone
    assert(years_until_retrofit_cost.setValue(0))
    argument_map['years_until_retrofit_cost'] = years_until_retrofit_cost

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result) #this displays the output when you run the test
    assert(result.value.valueName == 'Success')
    assert(result.info.size == 1)
    assert(result.warnings.size == 1)
  end

  def test_IncreaseInsulationRValueForExteriorWalls_EmptySpaceNoLoadsOrSurfaces
    # create an instance of the measure
    measure = IncreaseInsulationRValueForExteriorWalls.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # add a space to the model without any geometry or loads, want to make sure measure works or fails gracefully
    new_space = OpenStudio::Model::Space.new(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set all argument values

    count = -1

    r_value = arguments[count += 1].clone
    assert(r_value.setValue(10.0))
    argument_map['r_value'] = r_value

    allow_reduction = arguments[count += 1].clone
    assert(allow_reduction.setValue('false'))
    argument_map['allow_reduction'] = allow_reduction

    material_cost_increase_ip = arguments[count += 1].clone
    assert(material_cost_increase_ip.setValue(0.0))
    argument_map['material_cost_increase_ip'] = material_cost_increase_ip

    one_time_retrofit_cost_ip = arguments[count += 1].clone
    assert(one_time_retrofit_cost_ip.setValue(0.0))
    argument_map['one_time_retrofit_cost_ip'] = one_time_retrofit_cost_ip

    years_until_retrofit_cost = arguments[count += 1].clone
    assert(years_until_retrofit_cost.setValue(0))
    argument_map['years_until_retrofit_cost'] = years_until_retrofit_cost

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result) #this displays the output when you run the test
    assert(result.value.valueName == 'NA')
    assert(result.info.size == 1)
    assert(result.warnings.empty?)
  end

  def test_IncreaseInsulationRValueForExteriorWalls__AllowReduction
    # create an instance of the measure
    measure = IncreaseInsulationRValueForExteriorWalls.new

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

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set all argument values

    count = -1

    r_value = arguments[count += 1].clone
    assert(r_value.setValue(5.0))
    argument_map['r_value'] = r_value

    allow_reduction = arguments[count += 1].clone
    assert(allow_reduction.setValue('true'))
    argument_map['allow_reduction'] = allow_reduction

    material_cost_increase_ip = arguments[count += 1].clone
    assert(material_cost_increase_ip.setValue(0.0))
    argument_map['material_cost_increase_ip'] = material_cost_increase_ip

    one_time_retrofit_cost_ip = arguments[count += 1].clone
    assert(one_time_retrofit_cost_ip.setValue(0.0))
    argument_map['one_time_retrofit_cost_ip'] = one_time_retrofit_cost_ip

    years_until_retrofit_cost = arguments[count += 1].clone
    assert(years_until_retrofit_cost.setValue(0))
    argument_map['years_until_retrofit_cost'] = years_until_retrofit_cost

    measure.run(model, runner, argument_map)
    result = runner.result
    # show_output(result) #this displays the output when you run the test
    assert(result.value.valueName == 'Success')
    assert(result.info.size == 4)
    assert(result.warnings.size == 1)
  end

  def test_IncreaseInsulationRValueForExteriorWalls__no_mass
    # test file is 2.5.1
    if OpenStudio::VersionString.new(OpenStudio.openStudioVersion) >= OpenStudio::VersionString.new('2.5.1')

      # create an instance of the measure
      measure = IncreaseInsulationRValueForExteriorWalls.new

      # create an instance of a runner
      runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

      # load the test model
      translator = OpenStudio::OSVersion::VersionTranslator.new
      path = OpenStudio::Path.new(File.dirname(__FILE__) + '/no_mass.osm')
      model = translator.loadModel(path)
      assert(!model.empty?)
      model = model.get

      # get arguments and test that they are what we are expecting
      arguments = measure.arguments(model)

      # set argument values to good values and run the measure on model with spaces
      argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

      # set all argument values

      count = -1

      r_value = arguments[count += 1].clone
      assert(r_value.setValue(5.0))
      argument_map['r_value'] = r_value

      allow_reduction = arguments[count += 1].clone
      assert(allow_reduction.setValue('true'))
      argument_map['allow_reduction'] = allow_reduction

      material_cost_increase_ip = arguments[count += 1].clone
      assert(material_cost_increase_ip.setValue(0.0))
      argument_map['material_cost_increase_ip'] = material_cost_increase_ip

      one_time_retrofit_cost_ip = arguments[count += 1].clone
      assert(one_time_retrofit_cost_ip.setValue(0.0))
      argument_map['one_time_retrofit_cost_ip'] = one_time_retrofit_cost_ip

      years_until_retrofit_cost = arguments[count += 1].clone
      assert(years_until_retrofit_cost.setValue(0))
      argument_map['years_until_retrofit_cost'] = years_until_retrofit_cost

      measure.run(model, runner, argument_map)
      result = runner.result
      show_output(result) # this displays the output when you run the test
      assert(result.value.valueName == 'Success')
      # assert(result.info.size == 4)
      # assert(result.warnings.size == 1)
    end
  end
end
