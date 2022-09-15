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
