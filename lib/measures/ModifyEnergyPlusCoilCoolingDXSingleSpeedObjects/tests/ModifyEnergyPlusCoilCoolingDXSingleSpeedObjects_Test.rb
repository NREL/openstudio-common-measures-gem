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

class ModifyEnergyPlusCoilCoolingDXSingleSpeedObjects_Test < Minitest::Test
  def test_ModifyEnergyPlusCoilCoolingDXSingleSpeedObjects
    # create an instance of the measure
    measure = ModifyEnergyPlusCoilCoolingDXSingleSpeedObjects.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + '/Test.osm')
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

    ratedTotalCoolingCapacity = arguments[0].clone
    assert(ratedTotalCoolingCapacity.setValue('999.9'))
    argument_map['ratedTotalCoolingCapacity'] = ratedTotalCoolingCapacity

    ratedCOP = arguments[1].clone
    assert(ratedCOP.setValue('0.9999'))
    argument_map['ratedCOP'] = ratedCOP

    ratedAirFlowRate = arguments[2].clone
    assert(ratedAirFlowRate.setValue('0.9999'))
    argument_map['ratedAirFlowRate'] = ratedAirFlowRate

    condensateRemovalStart = arguments[3].clone
    assert(condensateRemovalStart.setValue('9.999'))
    argument_map['condensateRemovalStart'] = condensateRemovalStart

    evapLatentRatio = arguments[4].clone
    assert(evapLatentRatio.setValue('0.09999'))
    argument_map['evapLatentRatio'] = evapLatentRatio

    latentCapTimeConstant = arguments[5].clone
    assert(latentCapTimeConstant.setValue('9.999'))
    argument_map['latentCapTimeConstant'] = latentCapTimeConstant

    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    assert(result.warnings.empty?)
    assert(result.info.size == 12)
  end
end
