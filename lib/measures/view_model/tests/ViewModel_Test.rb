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

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'fileutils'

require 'minitest/autorun'

class ViewModel_Test < MiniTest::Unit::TestCase
    
  # paths to expected test files, includes osm and eplusout.sql
  def modelPath
    #return "#{File.dirname(__FILE__)}/SimpleModel.osm"
    return "#{File.dirname(__FILE__)}/ExampleModel.osm"
    #return "#{File.dirname(__FILE__)}/RotationTest.osm"
  end

  def reportPath
    return "#{File.dirname(__FILE__)}/output/report.json"
  end
  
  # create test files if they do not exist
  def setup

    if File.exist?(reportPath())
      FileUtils.rm(reportPath())
    end
    
    assert(File.exist?(modelPath()))
  end

  # delete output files
  def teardown
    
    # comment this out if you want to see the resulting report
    if File.exist?(reportPath())
      #FileUtils.rm(reportPath())
    end
  end
  
  # the actual test
  def test_ViewModel
     
    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    assert(File.exist?(modelPath()))
    model = translator.loadModel(modelPath())
    assert((not model.empty?))
    model = model.get
    
    # create an instance of the measure
    measure = ViewModel.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(0, arguments.size)

    current_dir = Dir.pwd
    run_dir = File.dirname(__FILE__) + '/output'
    FileUtils.rm_rf(run_dir) if File.exists?(run_dir)
    FileUtils.mkdir_p(run_dir)
    Dir.chdir(run_dir)
    
    # set argument values to good values and run the measure
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'NA')
    assert(result.warnings.size == 0)
    #assert(result.info.size == 1)
    
    Dir.chdir(current_dir)
    
    assert(File.exist?(reportPath()))
    
    # load the output in http://threejs.org/editor/ to test
    
  end  

end
