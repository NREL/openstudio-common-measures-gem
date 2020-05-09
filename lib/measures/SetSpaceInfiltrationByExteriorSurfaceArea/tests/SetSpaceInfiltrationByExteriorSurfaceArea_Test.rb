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
class SetSpaceInfiltrationByExteriorSurfaceArea_Test < Minitest::Test
  def test_SetSpaceInfiltrationByExteriorSurfaceArea_fail
    # create an instance of the measure
    measure = SetSpaceInfiltrationByExteriorSurfaceArea.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(4, arguments.size)
    assert_equal('infiltration_ip', arguments[0].name)

    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    infiltration_ip = arguments[0].clone
    assert(infiltration_ip.setValue(-20.0))
    argument_map['infiltration_ip'] = infiltration_ip
    measure.run(model, runner, argument_map)
    result = runner.result

    assert(result.value.valueName == 'Fail')
  end

  def test_SetSpaceInfiltrationByExteriorSurfaceArea_new
    # create an instance of the measure
    measure = SetSpaceInfiltrationByExteriorSurfaceArea.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    infiltration_ip = arguments[count += 1].clone
    assert(infiltration_ip.setValue(0.06))
    argument_map['infiltration_ip'] = infiltration_ip

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(3.0))
    argument_map['material_cost_ip'] = material_cost_ip

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0.1))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 2)
    assert(result.info.size == 4)
  end

  def test_SetSpaceInfiltrationByExteriorSurfaceArea_retrofit
    # create an instance of the measure
    measure = SetSpaceInfiltrationByExteriorSurfaceArea.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    infiltration_ip = arguments[count += 1].clone
    assert(infiltration_ip.setValue(0.06))
    argument_map['infiltration_ip'] = infiltration_ip

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(3.0))
    argument_map['material_cost_ip'] = material_cost_ip

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0.1))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 2)
    assert(result.info.size == 4)
  end

  def test_SetSpaceInfiltrationByExteriorSurfaceArea_retrofit_MinimalCost
    # create an instance of the measure
    measure = SetSpaceInfiltrationByExteriorSurfaceArea.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    infiltration_ip = arguments[count += 1].clone
    assert(infiltration_ip.setValue(0.06))
    argument_map['infiltration_ip'] = infiltration_ip

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(2.0))
    argument_map['material_cost_ip'] = material_cost_ip

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0.0))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 2)
    assert(result.info.size == 4)
  end

  def test_SetSpaceInfiltrationByExteriorSurfaceArea_retrofit_NoCost
    # create an instance of the measure
    measure = SetSpaceInfiltrationByExteriorSurfaceArea.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    infiltration_ip = arguments[count += 1].clone
    assert(infiltration_ip.setValue(0.06))
    argument_map['infiltration_ip'] = infiltration_ip

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(0.0))
    argument_map['material_cost_ip'] = material_cost_ip

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0.0))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 2)
    assert(result.info.size == 4)
  end

  def test_SetSpaceInfiltrationByExteriorSurfaceArea_ReverseTranslatedModel
    # create an instance of the measure
    measure = SetSpaceInfiltrationByExteriorSurfaceArea.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/ReverseTranslatedModel.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    infiltration_ip = arguments[count += 1].clone
    assert(infiltration_ip.setValue(0.06))
    argument_map['infiltration_ip'] = infiltration_ip

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(0.0))
    argument_map['material_cost_ip'] = material_cost_ip

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0.0))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 1)
    assert(result.info.size == 3)
  end

  def test_SetSpaceInfiltrationByExteriorSurfaceArea_EmptySpaceNoLoadsOrSurfaces
    # create an instance of the measure
    measure = SetSpaceInfiltrationByExteriorSurfaceArea.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # add a space to the model without any geometry or loads, want to make sure measure works or fails gracefully
    new_space = OpenStudio::Model::Space.new(model)

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    infiltration_ip = arguments[count += 1].clone
    assert(infiltration_ip.setValue(0.06))
    argument_map['infiltration_ip'] = infiltration_ip

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(0.0))
    argument_map['material_cost_ip'] = material_cost_ip

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0.0))
    argument_map['om_cost_ip'] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map['om_frequency'] = om_frequency

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 1)
    assert(result.info.size == 2)
  end
end
