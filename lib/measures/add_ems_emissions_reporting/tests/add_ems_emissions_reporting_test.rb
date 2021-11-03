# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
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

require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure'

class AddEMSEmissionsReporting_Test < MiniTest::Test

  def test_num_of_args_and_arg_names
    # create an instance of the measure
    measure = AddEMSEmissionsReporting.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    args = measure.arguments(model)
    assert_equal(6, args.size)
    assert_equal('future_subregion', args[0].name)
    assert_equal('hourly_historical_subregion', args[1].name)
    assert_equal('annual_historical_subregion', args[2].name)
    assert_equal('future_year', args[3].name)
    assert_equal('hourly_historical_year', args[4].name)
    assert_equal('annual_historical_year', args[5].name)
  end

  def test_good_arg_vals
    # create an instance of the measure
    measure = AddEMSEmissionsReporting.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    # runner = OpenStudio::Measure::OSRunner.new(osw)
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    trans = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/example_model.osm")
    model = trans.loadModel(path)
    assert(!model.empty?)
    model = model.get

    # get arguments
    args = measure.arguments(model)
    arg_map = OpenStudio::Measure.convertOSArgumentVectorToMap(args)

    # create hash of argument values
    args_hash = {}

    # populate argument with specified hash value if specified
    args.each do |arg|
      tmp_arg = arg.clone
      if args_hash.key?(arg.name)
        assert(tmp_arg.setValue(args_hash[arg.name]))
      end
      arg_map[arg.name] = tmp_arg
    end

    # run the measure
    measure.run(model, runner, arg_map)
    result = runner.result

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert(result.value.valueName == 'Success')

    # save the model to test output directory
    output_file_path = OpenStudio::Path.new("#{File.dirname(__FILE__)}/output/test_output.osm")
    model.save(output_file_path, true)
  end

end
