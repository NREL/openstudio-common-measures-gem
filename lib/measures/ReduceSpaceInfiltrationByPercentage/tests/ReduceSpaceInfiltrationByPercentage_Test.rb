# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2018, Alliance for Sustainable Energy, LLC.
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

class ReduceSpaceInfiltrationByPercentage_Test < Minitest::Test
  def test_ReduceSpaceInfiltrationByPercentage_01_BadInputs
    # create an instance of the measure
    measure = ReduceSpaceInfiltrationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(10, arguments.size)

    # fill in argument_map
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    space_type = arguments[count += 1].clone
    assert(space_type.setValue('*Entire Building*'))
    argument_map['space_type'] = space_type

    space_infiltration_reduction_percent = arguments[count += 1].clone
    assert(space_infiltration_reduction_percent.setValue(200.0))
    argument_map['space_infiltration_reduction_percent'] = space_infiltration_reduction_percent

    constant_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(1.0))
    argument_map['constant_coefficient'] = constant_coefficient
    temperature_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(0.0))
    argument_map['temperature_coefficient'] = temperature_coefficient
    wind_speed_coefficient = arguments[count += 1].clone
    assert(wind_speed_coefficient.setValue(0.0))
    argument_map['wind_speed_coefficient'] = wind_speed_coefficient
    wind_speed_squared_coefficient = arguments[count += 1].clone
    assert(wind_speed_squared_coefficient.setValue(0.0))
    argument_map['wind_speed_squared_coefficient'] = wind_speed_squared_coefficient

    alter_coef = arguments[count += 1].clone
    assert(alter_coef.setValue(true))
    argument_map['alter_coef'] = alter_coef

    material_and_installation_cost = arguments[count += 1].clone
    assert(material_and_installation_cost.setValue(0.0))
    argument_map['material_and_installation_cost'] = material_and_installation_cost

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.0))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    puts 'test_ReduceSpaceInfiltrationByPercentage_01_BadInputs'
    # show_output(result)
    assert(result.value.valueName == 'Fail')
  end

  #################################################################################################
  #################################################################################################

  def test_ReduceSpaceInfiltrationByPercentage_02_HighInputs
    # create an instance of the measure
    measure = ReduceSpaceInfiltrationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # refresh arguments
    arguments = measure.arguments(model)

    # set argument values to highish values and run the measure on empty model
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    space_type = arguments[count += 1].clone
    assert(space_type.setValue('*Entire Building*'))
    argument_map['space_type'] = space_type

    space_infiltration_reduction_percent = arguments[count += 1].clone
    assert(space_infiltration_reduction_percent.setValue(95.0))
    argument_map['space_infiltration_reduction_percent'] = space_infiltration_reduction_percent

    constant_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(1.0))
    argument_map['constant_coefficient'] = constant_coefficient
    temperature_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(0.0))
    argument_map['temperature_coefficient'] = temperature_coefficient
    wind_speed_coefficient = arguments[count += 1].clone
    assert(wind_speed_coefficient.setValue(0.0))
    argument_map['wind_speed_coefficient'] = wind_speed_coefficient
    wind_speed_squared_coefficient = arguments[count += 1].clone
    assert(wind_speed_squared_coefficient.setValue(0.0))
    argument_map['wind_speed_squared_coefficient'] = wind_speed_squared_coefficient

    alter_coef = arguments[count += 1].clone
    assert(alter_coef.setValue(true))
    argument_map['alter_coef'] = alter_coef

    material_and_installation_cost = arguments[count += 1].clone
    assert(material_and_installation_cost.setValue(0.0))
    argument_map['material_and_installation_cost'] = material_and_installation_cost

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.0))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    puts 'test_ReduceSpaceInfiltrationByPercentage_02_HighInputs'
    # show_output(result)
    assert(result.value.valueName == 'NA')
    # assert(result.info.size == 1)
    # assert(result.warnings.size == 1)
  end

  #################################################################################################
  #################################################################################################

  def test_ReduceSpaceInfiltrationByPercentage_03_EntireBuilding_FullyCosted
    # create an instance of the measure
    measure = ReduceSpaceInfiltrationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # refresh arguments
    arguments = measure.arguments(model)

    # set argument values to highish values and run the measure on empty model
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    space_type = arguments[count += 1].clone
    assert(space_type.setValue('*Entire Building*'))
    argument_map['space_type'] = space_type

    space_infiltration_reduction_percent = arguments[count += 1].clone
    assert(space_infiltration_reduction_percent.setValue(25.0))
    argument_map['space_infiltration_reduction_percent'] = space_infiltration_reduction_percent

    constant_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(1.0))
    argument_map['constant_coefficient'] = constant_coefficient
    temperature_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(0.0))
    argument_map['temperature_coefficient'] = temperature_coefficient
    wind_speed_coefficient = arguments[count += 1].clone
    assert(wind_speed_coefficient.setValue(0.0))
    argument_map['wind_speed_coefficient'] = wind_speed_coefficient
    wind_speed_squared_coefficient = arguments[count += 1].clone
    assert(wind_speed_squared_coefficient.setValue(0.0))
    argument_map['wind_speed_squared_coefficient'] = wind_speed_squared_coefficient

    alter_coef = arguments[count += 1].clone
    assert(alter_coef.setValue(true))
    argument_map['alter_coef'] = alter_coef

    material_and_installation_cost = arguments[count += 1].clone
    assert(material_and_installation_cost.setValue(10.0))
    argument_map['material_and_installation_cost'] = material_and_installation_cost

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.10))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    puts 'test_ReduceSpaceInfiltrationByPercentage_03_EntireBuilding_FullyCosted'
    result = runner.result
    # show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.info.size == 0)
    # assert(result.warnings.size == 2)
  end

  #################################################################################################
  #################################################################################################

  def test_ReduceSpaceInfiltrationByPercentage_03b_NoSurfaces
    # create an instance of the measure
    measure = ReduceSpaceInfiltrationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # remove all surfaces from test
    model.getSpaces.each do |space|
      # space.hardApplySpaceType(false)
      space.surfaces.each(&:remove)
    end

    # refresh arguments
    arguments = measure.arguments(model)

    # set argument values to highish values and run the measure on empty model
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    space_type = arguments[count += 1].clone
    assert(space_type.setValue('*Entire Building*'))
    argument_map['space_type'] = space_type

    space_infiltration_reduction_percent = arguments[count += 1].clone
    assert(space_infiltration_reduction_percent.setValue(25.0))
    argument_map['space_infiltration_reduction_percent'] = space_infiltration_reduction_percent

    constant_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(1.0))
    argument_map['constant_coefficient'] = constant_coefficient
    temperature_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(0.0))
    argument_map['temperature_coefficient'] = temperature_coefficient
    wind_speed_coefficient = arguments[count += 1].clone
    assert(wind_speed_coefficient.setValue(0.0))
    argument_map['wind_speed_coefficient'] = wind_speed_coefficient
    wind_speed_squared_coefficient = arguments[count += 1].clone
    assert(wind_speed_squared_coefficient.setValue(0.0))
    argument_map['wind_speed_squared_coefficient'] = wind_speed_squared_coefficient

    alter_coef = arguments[count += 1].clone
    assert(alter_coef.setValue(true))
    argument_map['alter_coef'] = alter_coef

    material_and_installation_cost = arguments[count += 1].clone
    assert(material_and_installation_cost.setValue(10.0))
    argument_map['material_and_installation_cost'] = material_and_installation_cost

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.10))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    puts 'test_ReduceSpaceInfiltrationByPercentage_03_EntireBuilding_FullyCosted'
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.info.size == 0)
    # assert(result.warnings.size == 2)
  end

  #################################################################################################
  #################################################################################################

  def test_ReduceSpaceInfiltrationByPercentage_04_SpaceTypeNoCosts
    # create an instance of the measure
    measure = ReduceSpaceInfiltrationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # re-load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01_FullyCosted.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # refresh arguments
    arguments = measure.arguments(model)

    # set argument values to highish values and run the measure on empty model
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    space_type = arguments[count += 1].clone
    assert(space_type.setValue('MultipleLights one LPD one Load x5 multiplier Same Schedule'))
    argument_map['space_type'] = space_type

    space_infiltration_reduction_percent = arguments[count += 1].clone
    assert(space_infiltration_reduction_percent.setValue(25.0))
    argument_map['space_infiltration_reduction_percent'] = space_infiltration_reduction_percent

    constant_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(1.0))
    argument_map['constant_coefficient'] = constant_coefficient
    temperature_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(0.0))
    argument_map['temperature_coefficient'] = temperature_coefficient
    wind_speed_coefficient = arguments[count += 1].clone
    assert(wind_speed_coefficient.setValue(0.0))
    argument_map['wind_speed_coefficient'] = wind_speed_coefficient
    wind_speed_squared_coefficient = arguments[count += 1].clone
    assert(wind_speed_squared_coefficient.setValue(0.0))
    argument_map['wind_speed_squared_coefficient'] = wind_speed_squared_coefficient

    alter_coef = arguments[count += 1].clone
    assert(alter_coef.setValue(true))
    argument_map['alter_coef'] = alter_coef

    material_and_installation_cost = arguments[count += 1].clone
    assert(material_and_installation_cost.setValue(0.0))
    argument_map['material_and_installation_cost'] = material_and_installation_cost

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.2))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(3))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    puts 'test_ReduceSpaceInfiltrationByPercentage_04_SpaceTypeNoCosts'
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.info.size == 0)
    # assert(result.warnings.size == 0)
  end

  def test_ReduceSpaceInfiltrationByPercentage_05_SpaceTypePartialCost
    # create an instance of the measure
    measure = ReduceSpaceInfiltrationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # re-load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01_FullyCosted.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # refresh arguments
    arguments = measure.arguments(model)

    # set argument values to highish values and run the measure on empty model
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    space_type = arguments[count += 1].clone
    assert(space_type.setValue('MultipleLights one LPD one Load x5 multiplier Same Schedule'))
    argument_map['space_type'] = space_type

    space_infiltration_reduction_percent = arguments[count += 1].clone
    assert(space_infiltration_reduction_percent.setValue(25.0))
    argument_map['space_infiltration_reduction_percent'] = space_infiltration_reduction_percent

    constant_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(1.0))
    argument_map['constant_coefficient'] = constant_coefficient
    temperature_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(0.0))
    argument_map['temperature_coefficient'] = temperature_coefficient
    wind_speed_coefficient = arguments[count += 1].clone
    assert(wind_speed_coefficient.setValue(0.0))
    argument_map['wind_speed_coefficient'] = wind_speed_coefficient
    wind_speed_squared_coefficient = arguments[count += 1].clone
    assert(wind_speed_squared_coefficient.setValue(0.0))
    argument_map['wind_speed_squared_coefficient'] = wind_speed_squared_coefficient

    alter_coef = arguments[count += 1].clone
    assert(alter_coef.setValue(true))
    argument_map['alter_coef'] = alter_coef

    material_and_installation_cost = arguments[count += 1].clone
    assert(material_and_installation_cost.setValue(20.0))
    argument_map['material_and_installation_cost'] = material_and_installation_cost

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.0))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    puts 'test_ReduceSpaceInfiltrationByPercentage_05_SpaceTypePartialCost'
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.info.size == 0)
    # assert(result.warnings.size == 0)
  end

  def test_ReduceSpaceInfiltrationByPercentage_06_SpaceTypeDemoInitialConst
    # create an instance of the measure
    measure = ReduceSpaceInfiltrationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # re-load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01_FullyCosted.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # refresh arguments
    arguments = measure.arguments(model)

    # set argument values to highish values and run the measure on empty model
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    space_type = arguments[count += 1].clone
    assert(space_type.setValue('MultipleLights one LPD one Load x5 multiplier Same Schedule'))
    argument_map['space_type'] = space_type

    space_infiltration_reduction_percent = arguments[count += 1].clone
    assert(space_infiltration_reduction_percent.setValue(25.0))
    argument_map['space_infiltration_reduction_percent'] = space_infiltration_reduction_percent

    constant_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(1.0))
    argument_map['constant_coefficient'] = constant_coefficient
    temperature_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(0.0))
    argument_map['temperature_coefficient'] = temperature_coefficient
    wind_speed_coefficient = arguments[count += 1].clone
    assert(wind_speed_coefficient.setValue(0.0))
    argument_map['wind_speed_coefficient'] = wind_speed_coefficient
    wind_speed_squared_coefficient = arguments[count += 1].clone
    assert(wind_speed_squared_coefficient.setValue(0.0))
    argument_map['wind_speed_squared_coefficient'] = wind_speed_squared_coefficient

    alter_coef = arguments[count += 1].clone
    assert(alter_coef.setValue(true))
    argument_map['alter_coef'] = alter_coef

    material_and_installation_cost = arguments[count += 1].clone
    assert(material_and_installation_cost.setValue(20.0))
    argument_map['material_and_installation_cost'] = material_and_installation_cost

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.0))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    puts 'test_ReduceSpaceInfiltrationByPercentage_06_SpaceTypeDemoInitialConst'
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.info.size == 1)
    # assert(result.warnings.size == 1)
  end

  def test_ReduceSpaceInfiltrationByPercentage_skip_coef
    # create an instance of the measure
    measure = ReduceSpaceInfiltrationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # re-load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01_FullyCosted.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # refresh arguments
    arguments = measure.arguments(model)

    # set argument values to highish values and run the measure on empty model
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    space_type = arguments[count += 1].clone
    assert(space_type.setValue('MultipleLights one LPD one Load x5 multiplier Same Schedule'))
    argument_map['space_type'] = space_type

    space_infiltration_reduction_percent = arguments[count += 1].clone
    assert(space_infiltration_reduction_percent.setValue(25.0))
    argument_map['space_infiltration_reduction_percent'] = space_infiltration_reduction_percent

    constant_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(1.0))
    argument_map['constant_coefficient'] = constant_coefficient
    temperature_coefficient = arguments[count += 1].clone
    assert(constant_coefficient.setValue(0.0))
    argument_map['temperature_coefficient'] = temperature_coefficient
    wind_speed_coefficient = arguments[count += 1].clone
    assert(wind_speed_coefficient.setValue(0.0))
    argument_map['wind_speed_coefficient'] = wind_speed_coefficient
    wind_speed_squared_coefficient = arguments[count += 1].clone
    assert(wind_speed_squared_coefficient.setValue(0.0))
    argument_map['wind_speed_squared_coefficient'] = wind_speed_squared_coefficient

    alter_coef = arguments[count += 1].clone
    assert(alter_coef.setValue(false))
    argument_map['alter_coef'] = alter_coef

    material_and_installation_cost = arguments[count += 1].clone
    assert(material_and_installation_cost.setValue(20.0))
    argument_map['material_and_installation_cost'] = material_and_installation_cost

    om_cost = arguments[count += 1].clone
    assert(om_cost.setValue(0.0))
    argument_map['om_cost'] = om_cost

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    puts 'test_ReduceSpaceInfiltrationByPercentage_skip_soef'
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.info.size == 1)
    # assert(result.warnings.size == 1)
  end

end
