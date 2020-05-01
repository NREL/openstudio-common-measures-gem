# frozen_string_literal: true

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

class ReduceVentilationByPercentage_Test < Minitest::Test
  def test_ReduceVentilationByPercentage_01_BadInputs
    # create an instance of the measure
    measure = ReduceVentilationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)

    # fill in argument_map
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    space_type = arguments[count += 1].clone
    assert(space_type.setValue('*Entire Building*'))
    argument_map['space_type'] = space_type

    design_spec_outdoor_air_reduction_percent = arguments[count += 1].clone
    assert(design_spec_outdoor_air_reduction_percent.setValue(200.0))
    argument_map['design_spec_outdoor_air_reduction_percent'] = design_spec_outdoor_air_reduction_percent

    measure.run(model, runner, argument_map)
    result = runner.result
    puts 'test_ReduceVentilationByPercentage_01_BadInputs'
    # show_output(result)
    assert(result.value.valueName == 'Fail')
  end

  #################################################################################################
  #################################################################################################

  def test_ReduceVentilationByPercentage_02_HighInputs
    # create an instance of the measure
    measure = ReduceVentilationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # re-load the test model
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

    design_spec_outdoor_air_reduction_percent = arguments[count += 1].clone
    assert(design_spec_outdoor_air_reduction_percent.setValue(95.0))
    argument_map['design_spec_outdoor_air_reduction_percent'] = design_spec_outdoor_air_reduction_percent

    measure.run(model, runner, argument_map)
    result = runner.result
    puts 'test_ReduceVentilationByPercentage_02_HighInputs'
    # show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.info.size == 1)
    # assert(result.warnings.size == 1)

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new(File.dirname(__FILE__) + '/output/test_output.osm')
    model.save(output_file_path, true)
  end

  #################################################################################################
  #################################################################################################

  def test_ReduceVentilationByPercentage_04_SpaceTypeNoCosts
    # create an instance of the measure
    measure = ReduceVentilationByPercentage.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # re-load the test model
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
    assert(space_type.setValue('MultipleLights one LPD one Load x5 multiplier Same Schedule'))
    argument_map['space_type'] = space_type

    design_spec_outdoor_air_reduction_percent = arguments[count += 1].clone
    assert(design_spec_outdoor_air_reduction_percent.setValue(25.0))
    argument_map['design_spec_outdoor_air_reduction_percent'] = design_spec_outdoor_air_reduction_percent

    measure.run(model, runner, argument_map)
    result = runner.result
    puts 'test_ReduceVentilationByPercentage_04_SpaceTypeNoCosts'
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.info.size == 0)
    # assert(result.warnings.size == 0)
  end

  #################################################################################################
  #################################################################################################

  # turning off this test until I can find the model that was used. I may have to re-create a similar model
  #   def test_ReduceVentilationByPercentage_05_SharedResource
  #
  #     # create an instance of the measure
  #     measure = ReduceVentilationByPercentage.new
  #
  #     # create an instance of a runner
  #     runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
  #
  #     # re-load the test model
  #     translator = OpenStudio::OSVersion::VersionTranslator.new
  #     path = OpenStudio::Path.new(File.dirname(__FILE__) + "/SpaceTypesShareDesignSpecOutdoorAir.osm")
  #     model = translator.loadModel(path)
  #
  #     assert((not model.empty?))
  #     model = model.get
  #
  #     # refresh arguments
  #     arguments = measure.arguments(model)
  #
  #     # set argument values to highish values and run the measure on empty model
  #     argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
  #
  #     count = -1
  #
  #     space_type = arguments[count += 1].clone
  #     assert(space_type.setValue("*Entire Building*"))
  #     argument_map["space_type"] = space_type
  #
  #     design_spec_outdoor_air_reduction_percent = arguments[count += 1].clone
  #     assert(design_spec_outdoor_air_reduction_percent.setValue(25.0))
  #     argument_map["design_spec_outdoor_air_reduction_percent"] = design_spec_outdoor_air_reduction_percent
  #
  #     measure.run(model, runner, argument_map)
  #     result = runner.result
  #     puts "test_ReduceVentilationByPercentage_04_SpaceTypeNoCosts"
  #     #show_output(result)
  #     assert(result.value.valueName == "Success")
  #     # assert(result.info.size == 0)
  #     # assert(result.warnings.size == 0)
  #
  #   end
end
