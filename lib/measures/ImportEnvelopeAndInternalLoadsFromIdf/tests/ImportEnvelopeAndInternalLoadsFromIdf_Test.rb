# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require 'minitest/autorun'

class ImportEnvelopeAndInternalLoadsFromIdf_Test < Minitest::Test
  def test_ImportEnvelopeAndInternalLoadsFromIdf
    skip # test uses old idf files as input. No easy way to currently upgrade within test unless it is updated to make an IDF from OSM, but that limits the kinds of test models that can be used

    # create an instance of the measure
    measure = ImportEnvelopeAndInternalLoadsFromIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/measure_test.osw')
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    source_idf_path = arguments[0].clone
    assert(source_idf_path.setValue(File.dirname(__FILE__) + '/RefBldgLargeHotelNew2004_Chicago.idf'))
    argument_map['source_idf_path'] = source_idf_path

    import_site_objects = arguments[1].clone
    assert(import_site_objects.setValue(true))
    argument_map['import_site_objects'] = import_site_objects

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 1)
    # assert(result.info.size == 2)

    # save the model in an output directory
    output_dir = File.expand_path('output', File.dirname(__FILE__))
    FileUtils.mkdir output_dir unless Dir.exist? output_dir
    model.save("#{output_dir}/test.osm", true)
  end

  def test_ImportEnvelopeAndInternalLoadsFromIdf_exteriorLightsAndShadingSurfaces
    skip # test uses old idf files as input. No easy way to currently upgrade within test unless it is updated to make an IDF from OSM, but that limits the kinds of test models that can be used

    # create an instance of the measure
    measure = ImportEnvelopeAndInternalLoadsFromIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/measure_test.osw')
    osw = OpenStudio::WorkflowJSON.load(osw_path).get
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    source_idf_path = arguments[0].clone
    assert(source_idf_path.setValue(File.dirname(__FILE__) + '/ExtLightsAndShading.idf'))
    argument_map['source_idf_path'] = source_idf_path

    import_site_objects = arguments[1].clone
    assert(import_site_objects.setValue(true))
    argument_map['import_site_objects'] = import_site_objects

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 1)
    # assert(result.info.size == 2)

    # save the model
    # output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + "/test.osm")
    # model.save(output_file_path,true)
  end
end
