# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
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
