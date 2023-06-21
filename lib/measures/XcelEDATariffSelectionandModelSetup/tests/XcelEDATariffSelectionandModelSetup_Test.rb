# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'minitest/autorun'

class XcelEDATariffSelectionandModelSetup_Test < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_XcelEDATariffSelectionandModelSetup_NumInputs
    # create an instance of the measure
    measure = XcelEDATariffSelectionandModelSetup.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    assert_equal(2, arguments.size)
    assert_equal('elec_tar', arguments[0].name)
    assert_equal('gas_tar', arguments[1].name)
    assert(arguments[0].hasDefaultValue)
    assert(arguments[1].hasDefaultValue)
  end

  def test_XcelEDATariffSelectionandModelSetup_empty_model

    # create an instance of the measure
    measure = XcelEDATariffSelectionandModelSetup.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new
    model.getTimestep

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)

    # set argument values to good values and run the measure on the workspace
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    elec_tar = arguments[0].clone
    assert(elec_tar.setValue('Secondary General'))
    argument_map['elec_tar'] = elec_tar
    gas_tar = arguments[1].clone
    assert(gas_tar.setValue('Large CG'))
    argument_map['gas_tar'] = gas_tar
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 15)
  end

  def test_XcelEDATariffSelectionandModelSetup_good_model
    # create an instance of the measure
    measure = XcelEDATariffSelectionandModelSetup.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # forward translate OSM file to IDF file
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)

    # set argument values to good values and run the measure on the workspace
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    elec_tar = arguments[0].clone
    assert(elec_tar.setValue('Secondary General'))
    argument_map['elec_tar'] = elec_tar
    gas_tar = arguments[1].clone
    assert(gas_tar.setValue('Large CG'))
    argument_map['gas_tar'] = gas_tar
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 15)
  end
end
