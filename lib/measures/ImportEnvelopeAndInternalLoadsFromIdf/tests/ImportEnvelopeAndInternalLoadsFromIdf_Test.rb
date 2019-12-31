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

class ImportEnvelopeAndInternalLoadsFromIdf_Test < Minitest::Test
  def test_ImportEnvelopeAndInternalLoadsFromIdf

    skip # test uses old idf files as input. No easy way to currently upgrade within test unless it is updated to make an IDF from OSM, but that limits the kinds of test models that can be used

    # create an instance of the measure
    measure = ImportEnvelopeAndInternalLoadsFromIdf.new

    # create an instance of a runner with OSW
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/test.osw')
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
    osw_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/test.osw')
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
