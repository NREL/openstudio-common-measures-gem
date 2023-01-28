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

class GenericQAQC_Test < Minitest::Test
  def is_openstudio_2?
    begin
      workflow = OpenStudio::WorkflowJSON.new
    rescue StandardError
      return false
    end
    return true
  end

  def model_in_path_default
    return "#{File.dirname(__FILE__)}/ExampleModel.osm"
  end

  def epw_path_default
    # make sure we have a weather data location
    epw = nil
    epw = OpenStudio::Path.new("#{File.dirname(__FILE__)}/USA_TX_Austin-Mueller.Muni.AP.722540_TMY3.epw")
    assert(File.exist?(epw.to_s))
    return epw.to_s
  end

  def run_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def model_out_path(test_name)
    "#{run_dir(test_name)}/TestOutput.osm"
  end

  def workspace_path(test_name)
    if is_openstudio_2?
      return "#{run_dir(test_name)}/run/in.idf"
    else
      return "#{run_dir(test_name)}/ModelToIdf/in.idf"
    end
  end

  def sql_path(test_name)
    if is_openstudio_2?
      return "#{run_dir(test_name)}/run/eplusout.sql"
    else
      return "#{run_dir(test_name)}/ModelToIdf/EnergyPlusPreProcess-0/EnergyPlus-0/eplusout.sql"
    end
  end

  def report_path(test_name)
    "#{run_dir(test_name)}/report.html"
  end

  # create test files if they do not exist when the test first runs
  def setup_test(test_name, idf_output_requests, model_in_path = model_in_path_default, epw_path = epw_path_default)
    if !File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end

    assert(File.exist?(model_in_path))

    if File.exist?(model_out_path(test_name))
      FileUtils.rm(model_out_path(test_name))
    end

    # convert output requests to OSM for testing, OS App and PAT will add these to the E+ Idf
    workspace = OpenStudio::Workspace.new('Draft'.to_StrictnessLevel, 'EnergyPlus'.to_IddFileType)
    workspace.addObjects(idf_output_requests)
    rt = OpenStudio::EnergyPlus::ReverseTranslator.new
    request_model = rt.translateWorkspace(workspace)

    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_in_path)
    assert(!model.empty?)
    model = model.get
    model.addObjects(request_model.objects)
    model.save(model_out_path(test_name), true)

    if ENV['OPENSTUDIO_TEST_NO_CACHE_SQLFILE']
      if File.exist?(sql_path(test_name))
        FileUtils.rm_f(sql_path(test_name))
      end
    end

    if !File.exist?(sql_path(test_name))
      osw_path = File.join(run_dir(test_name), 'in.osw')
      osw_path = File.absolute_path(osw_path)

      workflow = OpenStudio::WorkflowJSON.new
      workflow.setSeedFile(File.absolute_path(model_out_path(test_name)))
      workflow.setWeatherFile(File.absolute_path(epw_path))
      workflow.saveAs(osw_path)

      cli_path = OpenStudio.getOpenStudioCLI
      cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
      puts cmd
      system(cmd)
    end
  end

  # use this when model using may be outdated
  def model_vers_trans(model_path)
    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(model_path)
    assert(!model.empty?)
    model = model.get

    return model
  end

  # assert that no section errors were thrown
  def section_errors(runner)
    # loop through a number of possible messages to trigger error if found
    test_strings = []
    test_strings << 'Error prevented QAQC check from running'
    test_strings << "Can't calculate target EUI. Make sure model has expected climate zone and building type."
    test_strings << "Can't calculate target end use EUIs. Make sure model has expected climate zone and building type."
    test_strings << "Didn't find construction for"
    # test_strings << "Annual average of 0 gallons per day of hot water" # confirm that no test models have non zero SWH value

    section_errors = []

    test_strings.each do |test_string|
      if is_openstudio_2?
        runner.result.stepWarnings.each do |warning|
          if warning.include?(test_string)
            section_errors << warning
          end
        end
        assert(section_errors.empty?)
      else
        runner.result.warnings.each do |warning|
          if warning.logMessage.include?(test_string)
            section_errors << warning
          end
        end
        assert(section_errors.empty?)
      end
    end

    return section_errors
  end

  # test pass
  def test_GenericQAQC_pass
    # skip "Broken in 2.5.1, address immediately"

    # setup test name, model, and epw
    test_name = 'pass'
    model_in_path = "#{File.dirname(__FILE__)}/BasicOfficeTest_Mueller.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_TX_Austin-Mueller.Muni.AP.722540_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(!idf_output_requests.empty?)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  def test_GenericQAQC_alt_hvac_a
    # skip "Broken in 2.5.1, address immediately"

    # setup test name, model, and epw
    test_name = 'alt_hvac_a'
    model_in_path = "#{File.dirname(__FILE__)}/BasicOfficeTest_Mueller_altHVAC_a.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_TX_Austin-Mueller.Muni.AP.722540_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # assert(idf_output_requests.size > 0) # todo - see if this is issue

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors (for this test only 2.5.1 or higher)
      unless OpenStudio::VersionString.new(OpenStudio.openStudioVersion) < OpenStudio::VersionString.new('2.5.1')
        assert(section_errors(runner).empty?)
      end
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  def test_GenericQAQC_alt_hvac_b
    # skip "Broken in 2.5.1, address immediately"

    # setup test name, model, and epw
    test_name = 'alt_hvac_b'
    model_in_path = "#{File.dirname(__FILE__)}/BasicOfficeTest_Mueller_altHVAC_b.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_TX_Austin-Mueller.Muni.AP.722540_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # assert(idf_output_requests.size > 0) # todo - see if this is issue

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # test fail_a
  def test_GenericQAQC_fail_a
    # setup test name, model, and epw
    test_name = 'fail_a'
    model_in_path = "#{File.dirname(__FILE__)}/BasicOfficeTest_Mabry.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_TX_Austin-Camp.Mabry.722544_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(idf_output_requests.empty?) # no airTerminalSingleDuctVAVReheats

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # test fail_b
  def test_GenericQAQC_fail_b
    # setup test name, model, and epw
    test_name = 'fail_b'
    model_in_path = "#{File.dirname(__FILE__)}/BasicOfficeTest.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_CO_Golden-NREL.724666_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    assert(idf_output_requests.empty?) # no airTerminalSingleDuctVAVReheats

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      # this model has no climate zone and is expected to have sections that fail lookup, so comment out the assert related to error messages.
      # assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  def test_GenericQAQC_res_a
    # test file is 2.6.0
    if OpenStudio::VersionString.new(OpenStudio.openStudioVersion) >= OpenStudio::VersionString.new('2.6.0')

      # setup test name, model, and epw
      test_name = 'res_a'
      model_in_path = "#{File.dirname(__FILE__)}/MidRiseApt.osm"
      epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_TX_Austin-Mueller.Muni.AP.722540_TMY3.epw')

      # create an instance of the measure
      measure = GenericQAQC.new

      # create an instance of a runner
      runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
      runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

      # get arguments
      arguments = measure.arguments
      argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

      # get the energyplus output requests, this will be done automatically by OS App and PAT
      idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
      assert(!idf_output_requests.empty?)

      # mimic the process of running this measure in OS App or PAT
      setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

      assert(File.exist?(model_out_path(test_name)))
      assert(File.exist?(sql_path(test_name)))
      assert(File.exist?(epw.to_s))

      # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
      runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
      runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
      runner.setLastEpwFilePath(epw.to_s)
      runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

      # delete the output if it exists
      if File.exist?(report_path(test_name))
        FileUtils.rm(report_path(test_name))
      end
      assert(!File.exist?(report_path(test_name)))

      # temporarily change directory to the run directory and run the measure
      start_dir = Dir.pwd
      begin
        Dir.chdir(run_dir(test_name))

        # run the measure
        measure.run(runner, argument_map)
        result = runner.result
        show_output(result)
        assert_equal('Success', result.value.valueName)

        # look for section_errors
        assert(section_errors(runner).empty?)
      ensure
        Dir.chdir(start_dir)
      end

      # make sure the report file exists
      assert(File.exist?(report_path(test_name)))
    end
  end

  # test 0422_sm_off
  def test_GenericQAQC_0422_sm_off
    # setup test name, model, and epw
    test_name = '0422_sm_off'
    model_in_path = "#{File.dirname(__FILE__)}/0422_test_b_sm_off.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_TX_Austin-Mueller.Muni.AP.722540_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

    # test 0422_sm_off
  def test_GenericQAQC_0422_sm_off_2019
    # setup test name, model, and epw
    test_name = '0422_sm_off_2019'
    model_in_path = "#{File.dirname(__FILE__)}/0422_test_b_sm_off.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_TX_Austin-Mueller.Muni.AP.722540_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['template'] = '90.1-2019'

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # test 0422_sm_off
  def test_GenericQAQC_0422_sm_off_comstock2013
    # setup test name, model, and epw
    test_name = '0422_sm_off_comstock2013'
    model_in_path = "#{File.dirname(__FILE__)}/0422_test_b_sm_off.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_TX_Austin-Mueller.Muni.AP.722540_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['template'] = 'ComStock 90.1-2013'

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # test_fsr
  def test_fsr
    # setup test name, model, and epw
    test_name = 'fsr'
    model_in_path = "#{File.dirname(__FILE__)}/fsr.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_CO_Golden-NREL.724666_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['template'] = '90.1-2010'

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # test uo_lg_hotel
  def test_uo_lg_hotel
    # setup test name, model, and epw
    test_name = 'uo_lg_hotel'
    model_in_path = "#{File.dirname(__FILE__)}/uo_lg_hotel.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_NY_Buffalo-Greater.Buffalo.Intl.AP.725280_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['template'] = '90.1-2013'

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # test uo_strip_mall
  def test_uo_strip_mall
    # setup test name, model, and epw
    test_name = 'uo_strip_mall'
    model_in_path = "#{File.dirname(__FILE__)}/uo_strip_mall.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_NY_Buffalo-Greater.Buffalo.Intl.AP.725280_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['template'] = '90.1-2004'

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      #assert(section_errors(runner).empty?) # todo enable when building type lookup for StripMall is fixed
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # test uo_blend
  def test_uo_blend
    # setup test name, model, and epw
    test_name = 'uo_blend'
    model_in_path = "#{File.dirname(__FILE__)}/uo_blend.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_NY_Buffalo-Greater.Buffalo.Intl.AP.725280_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['template'] = '90.1-2007'

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

  # test uo_mixed
  def test_uo_mixed
    # setup test name, model, and epw
    test_name = 'uo_mixed'
    model_in_path = "#{File.dirname(__FILE__)}/uo_mixed.osm"
    epw = OpenStudio::Path.new(File.dirname(__FILE__)) / OpenStudio::Path.new('USA_NY_Buffalo-Greater.Buffalo.Intl.AP.725280_TMY3.epw')

    # create an instance of the measure
    measure = GenericQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)
    runner.setLastOpenStudioModel(model_vers_trans(model_in_path))

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}
    args_hash['template'] = '90.1-2013'

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # get the energyplus output requests, this will be done automatically by OS App and PAT
    idf_output_requests = measure.energyPlusOutputRequests(runner, argument_map)
    # assert(idf_output_requests.size > 0)

    # mimic the process of running this measure in OS App or PAT
    setup_test(test_name, idf_output_requests, model_in_path, epw.to_s)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw.to_s))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw.to_s)
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))

    # delete the output if it exists
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end
    assert(!File.exist?(report_path(test_name)))

    # temporarily change directory to the run directory and run the measure
    start_dir = Dir.pwd
    begin
      Dir.chdir(run_dir(test_name))

      # run the measure
      measure.run(runner, argument_map)
      result = runner.result
      show_output(result)
      assert_equal('Success', result.value.valueName)

      # look for section_errors
      assert(section_errors(runner).empty?)
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))
  end

end
