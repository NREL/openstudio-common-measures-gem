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

class XcelEDAReportingandQAQC_Test < Minitest::Test
  def is_openstudio_2?
    begin
      workflow = OpenStudio::WorkflowJSON.new
    rescue StandardError
      return false
    end
    return true
  end

  def model_in_path_default
    return "#{File.dirname(__FILE__)}/0116_OfficeTest121_dev.osm"
  end

  def epw_path_default
    # make sure we have a weather data location
    epw = nil
    epw = OpenStudio::Path.new("#{File.dirname(__FILE__)}/USA_CO_Golden-NREL.724666_TMY3.epw")
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
    "#{run_dir(test_name)}/report.xml"
  end

  # method for running the test simulation using OpenStudio 1.x API
  def setup_test_1(test_name, epw_path)
    co = OpenStudio::Runmanager::ConfigOptions.new(true)
    co.findTools(false, true, false, true)

    if !File.exist?(sql_path(test_name))
      puts 'Running EnergyPlus'

      wf = OpenStudio::Runmanager::Workflow.new('modeltoidf->energypluspreprocess->energyplus')
      wf.add(co.getTools)
      job = wf.create(OpenStudio::Path.new(run_dir(test_name)), OpenStudio::Path.new(model_out_path(test_name)), OpenStudio::Path.new(epw_path))

      rm = OpenStudio::Runmanager::RunManager.new
      rm.enqueue(job, true)
      rm.waitForFinished
    end
  end

  # method for running the test simulation using OpenStudio 2.x API
  def setup_test_2(test_name, epw_path)
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
    
    if is_openstudio_2?
      setup_test_2(test_name, epw_path)
    else
      setup_test_1(test_name, epw_path)
    end
  end

  def test_example_model
    #skip "Broken in 2.5.1, address immediately"

    test_name = 'test_example_model'
    model_in_path = model_in_path_default

    # create an instance of the measure
    measure = XcelEDAReportingandQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}

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
    assert_equal(1, idf_output_requests.size)

    # mimic the process of running this measure in OS App or PAT
    epw_path = epw_path_default
    setup_test(test_name, idf_output_requests, model_in_path)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw_path))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
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
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))

    # Ensure that the peak demand value is set
    peak_demand_val = -999.9
    result.stepValues.each do |value|
      if value.name == 'annual_demand_electricity_peak_demand'
        peak_demand_val = value.valueAsDouble
        break
      end
    end
    expected_peak_demand_val = 59.8
    assert_in_delta(expected_peak_demand_val, peak_demand_val, 0.5, "Expected an annual peak within 0.5kW of #{expected_peak_demand_val} but got #{peak_demand_val}")

    # Ensure that the total kWh is equal to sum of kWh from all TOU periods
    total_gj_all_tou_periods = 0.0
    annual_gj_elec = nil
    tou_periods = []
    result.stepValues.each do |value|
      if value.name.include?('annual_consumption_electricity_tou_')
        total_gj_all_tou_periods += value.valueAsDouble
        tou_periods << value.name.gsub('annual_consumption_electricity_tou_','')
        puts "Found #{value.valueAsDouble} in TOU period #{value.name.gsub('annual_consumption_electricity_tou_','')}"
      elsif value.name == 'annual_consumption_electricity'
        annual_gj_elec = value.valueAsDouble
      end
    end
    assert(!annual_gj_elec.nil?, 'annual_consumption_electricity was not found in the runner.registerValue outputs')
    assert_in_delta(annual_gj_elec, total_gj_all_tou_periods, 0.5, "Expected an annual GJ of #{annual_gj_elec} for sum of all time of use periods, but got #{total_gj_all_tou_periods}")

    # Ensure that the district cooling kWh is equal to sum of kWh from all TOU periods
    total_dist_clg_gj_all_tou_periods = 0.0
    some_dist_clg_tou_periods_found = false
    annual_gj_dist_clg = nil
    tou_periods = []
    result.stepValues.each do |value|
      if value.name.include?('annual_consumption_district_cooling_tou_')
        total_gj_all_tou_periods += value.valueAsDouble
        tou_periods << value.name.gsub('annual_consumption_district_cooling_tou_','')
        some_dist_clg_tou_periods_found = true
        puts "Found #{value.valueAsDouble} in TOU period #{value.name.gsub('annual_consumption_district_cooling_tou_','')}"
      elsif value.name == 'annual_consumption_district_cooling'
        annual_gj_dist_clg = value.valueAsDouble
      end
    end
    assert(!total_dist_clg_gj_all_tou_periods.nil?, 'annual_consumption_district_cooling was not found in the runner.registerValue outputs')
    assert(some_dist_clg_tou_periods_found, 'No TOU district cooling periods were found in runner.registerValue outputs')
    assert_in_delta(annual_gj_dist_clg, total_dist_clg_gj_all_tou_periods, 0.5, "Expected an annual GJ of #{annual_gj_dist_clg} for sum of all time of use periods, but got #{total_dist_clg_gj_all_tou_periods}")
  end

  def test_district_cooling_model
    skip # invalid test model, enable test if I can find this model
    test_name = 'test_district_cooling_model'
    model_in_path = "#{File.dirname(__FILE__)}/0116_OfficeTest_dist_clg.osm"

    # create an instance of the measure
    measure = XcelEDAReportingandQAQC.new

    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # get arguments
    arguments = measure.arguments
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values
    args_hash = {}

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
    assert_equal(1, idf_output_requests.size)

    # mimic the process of running this measure in OS App or PAT
    epw_path = epw_path_default
    setup_test(test_name, idf_output_requests, model_in_path)

    assert(File.exist?(model_out_path(test_name)))
    assert(File.exist?(sql_path(test_name)))
    assert(File.exist?(epw_path))

    # set up runner, this will happen automatically when measure is run in PAT or OpenStudio
    runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_out_path(test_name)))
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspace_path(test_name)))
    runner.setLastEpwFilePath(epw_path)
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
    ensure
      Dir.chdir(start_dir)
    end

    # make sure the report file exists
    assert(File.exist?(report_path(test_name)))

    # Ensure that the peak demand value is set
    peak_demand_val = -999.9
    result.stepValues.each do |value|
      if value.name == 'annual_demand_electricity_peak_demand'
        peak_demand_val = value.valueAsDouble
        break
      end
    end
    expected_peak_demand_val = 25.9
    assert_in_delta(expected_peak_demand_val, peak_demand_val, 0.5, "Expected an annual peak within 0.5kW of #{expected_peak_demand_val} but got #{peak_demand_val}")

    # Ensure that the total kWh is equal to sum of kWh from all TOU periods
    total_gj_all_tou_periods = 0.0
    annual_gj_elec = nil
    tou_periods = []
    result.stepValues.each do |value|
      if value.name.include?('annual_consumption_electricity_tou_')
        total_gj_all_tou_periods += value.valueAsDouble
        tou_periods << value.name.gsub('annual_consumption_electricity_tou_','')
        puts "Found #{value.valueAsDouble} in TOU period #{value.name.gsub('annual_consumption_electricity_tou_','')}"
      elsif value.name == 'annual_consumption_electricity'
        annual_gj_elec = value.valueAsDouble
      end
    end
    assert(!annual_gj_elec.nil?, 'annual_consumption_electricity was not found in the runner.registerValue outputs')
    assert_in_delta(annual_gj_elec, total_gj_all_tou_periods, 0.5, "Expected an annual GJ of #{annual_gj_elec} for sum of all time of use periods, but got #{total_gj_all_tou_periods}")

    # Ensure that the district cooling kWh is equal to sum of kWh from all TOU periods
    total_dist_clg_gj_all_tou_periods = 0.0
    some_dist_clg_tou_periods_found = false
    annual_gj_dist_clg = nil
    tou_periods = []
    result.stepValues.each do |value|
      if value.name.include?('annual_consumption_district_cooling_tou_')
        total_dist_clg_gj_all_tou_periods += value.valueAsDouble
        tou_periods << value.name.gsub('annual_consumption_district_cooling_tou_','')
        some_dist_clg_tou_periods_found = true
        puts "Found #{value.valueAsDouble} in TOU period #{value.name.gsub('annual_consumption_district_cooling_tou_','')}"
      elsif value.name == 'annual_consumption_district_cooling'
        annual_gj_dist_clg = value.valueAsDouble
      end
    end
    assert(!total_dist_clg_gj_all_tou_periods.nil?, 'annual_consumption_district_cooling was not found in the runner.registerValue outputs')
    assert(some_dist_clg_tou_periods_found, 'No TOU district cooling periods were found in runner.registerValue outputs')
    assert_in_delta(annual_gj_dist_clg, total_dist_clg_gj_all_tou_periods, 0.5, "Expected an annual GJ of #{annual_gj_dist_clg} for sum of all time of use periods, but got #{total_dist_clg_gj_all_tou_periods}")
  end
end
