# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2022, Alliance for Sustainable Energy, LLC.
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
class SwapLightsDefinition_Test < Minitest::Test
  def test_SwapLightsDefinition_fail
    # create an instance of the measure
    measure = SwapLightsDefinition.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)
    count = -1
    assert_equal('old_lights_def', arguments[count += 1].name)
    assert_equal('new_lights_def', arguments[count += 1].name)
    assert_equal('demo_cost_initial_const', arguments[count += 1].name)
    # set argument values to bad values and run the measure
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)
    measure.run(model, runner, argument_map)
    result = runner.result
    assert(result.value.valueName == 'Fail')
  end

  def test_SwapLightsDefinition_good_UnusedLight
    # code below provides more detailed logging
    # OpenStudio::Logger.instance.standardOutLogger.enable
    # OpenStudio::Logger.instance.standardOutLogger.setLogLevel(-1)

    # create an instance of the measure
    measure = SwapLightsDefinition.new

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

    old_lights_def = arguments[count += 1].clone
    assert(old_lights_def.setValue('ASHRAE_189.1-2009_ClimateZone 1-3_LargeHotel_Banquet_LightsDef'))
    argument_map['old_lights_def'] = old_lights_def

    new_lights_def = arguments[count += 1].clone
    assert(new_lights_def.setValue('ASHRAE 189.1-2009 ClimateZone 4-8 MediumOffice LightsDef'))
    argument_map['new_lights_def'] = new_lights_def

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 1)
  end

  def test_SwapLightsDefinition_good_UsedLight
    # create an instance of the measure
    measure = SwapLightsDefinition.new

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

    old_lights_def = arguments[count += 1].clone
    assert(old_lights_def.setValue('ASHRAE_189.1-2009_ClimateZone 1-3_LargeHotel_Banquet_LightsDef'))
    argument_map['old_lights_def'] = old_lights_def

    new_lights_def = arguments[count += 1].clone
    assert(new_lights_def.setValue('ASHRAE_189.1-2009_ClimateZone 1-3_LargeHotel_Kitchen_LightsDef'))
    argument_map['new_lights_def'] = new_lights_def

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 1)

    # save the model
    # output_file_path = OpenStudio::Path.new('C:\SVN_Utilities\OpenStudio\measures\test.osm')
    # model.save(output_file_path,true)
  end

  def test_SwapLightsDefinition_warning_calc_method_mismatch
    # create an instance of the measure
    measure = SwapLightsDefinition.new

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

    old_lights_def = arguments[count += 1].clone
    assert(old_lights_def.setValue('ASHRAE_189.1-2009_ClimateZone 1-3_LargeHotel_Banquet_LightsDef'))
    argument_map['old_lights_def'] = old_lights_def

    new_lights_def = arguments[count += 1].clone
    assert(new_lights_def.setValue('100W light'))
    argument_map['new_lights_def'] = new_lights_def

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.size == 1)
    assert(result.info.size == 1)

    # save the model
    # output_file_path = OpenStudio::Path.new('C:\SVN_Utilities\OpenStudio\measures\test.osm')
    # model.save(output_file_path,true)
  end

  def test_SwapLightsDefinition_good_UnusedLight_Costed
    # code below provides more detailed logging
    # OpenStudio::Logger.instance.standardOutLogger.enable
    # OpenStudio::Logger.instance.standardOutLogger.setLogLevel(-1)

    # create an instance of the measure
    measure = SwapLightsDefinition.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/EnvelopeAndLoadTestModel_01_costed.osm')
    model = translator.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # set argument values to good values and run the measure on model with spaces
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    count = -1

    old_lights_def = arguments[count += 1].clone
    assert(old_lights_def.setValue('ASHRAE_189.1-2009_ClimateZone 1-3_LargeHotel_Banquet_LightsDef'))
    argument_map['old_lights_def'] = old_lights_def

    new_lights_def = arguments[count += 1].clone
    assert(new_lights_def.setValue('ASHRAE 189.1-2009 ClimateZone 4-8 MediumOffice LightsDef'))
    argument_map['new_lights_def'] = new_lights_def

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(true))
    argument_map['demo_cost_initial_const'] = demo_cost_initial_const

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 2)
  end
end
