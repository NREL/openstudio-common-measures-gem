# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'fileutils'

require 'minitest/autorun'

class ViewData_Test < MiniTest::Unit::TestCase
  # paths to expected test files, includes osm and eplusout.sql
  def modelPath
    return "#{File.dirname(__FILE__)}/ExampleModel.osm"
  end

  def workspacePath
    return "#{File.dirname(__FILE__)}/output/ExampleModel/ModelToIdf/EnergyPlusPreProcess-0/out.idf"
  end

  def epwPath
    return "#{File.dirname(__FILE__)}/USA_CO_Golden-NREL.724666_TMY3.epw"
  end

  def runDir
    return "#{File.dirname(__FILE__)}/output/ExampleModel/"
  end

  def sqlPath
    return "#{File.dirname(__FILE__)}/output/ExampleModel/ModelToIdf/EnergyPlusPreProcess-0/EnergyPlus-0/eplusout.sql"
  end

  def hasGeometryDiagnostics
    return Gem::Version.new(OpenStudio.openStudioVersion) > Gem::Version.new('3.6.1')
  end

  def numArguments
    return hasGeometryDiagnostics ? 6 : 5
  end

  # create test files if they do not exist
  def setup
    assert(File.exist?(modelPath))

    if !File.exist?(runDir)
      FileUtils.mkdir_p(runDir)
    end
    assert(File.exist?(runDir))

    if !File.exist?(sqlPath)
      puts 'Running EnergyPlus'

      vt = OpenStudio::OSVersion::VersionTranslator.new
      model = vt.loadModel(modelPath)
      assert(model.is_initialized)
      model = model.get

      # make sure output requests are in pre-run model, this will happen automatically in PAT
      var = OpenStudio::Model::OutputVariable.new('Surface Outside Face Temperature', model)
      var.setReportingFrequency('Hourly')

      var = OpenStudio::Model::OutputVariable.new('Surface Inside Face Temperature', model)
      var.setReportingFrequency('Hourly')

      var = OpenStudio::Model::OutputVariable.new('Zone Mean Air Temperature', model)
      var.setReportingFrequency('Hourly')

      var = OpenStudio::Model::OutputVariable.new('Zone Air System Sensible Cooling Rate', model)
      var.setReportingFrequency('Hourly')

      # make sure output requests are in pre-run model, this will happen automatically in PAT
      var = OpenStudio::Model::OutputVariable.new('Surface Outside Face Temperature', model)
      var.setReportingFrequency('Timestep')

      var = OpenStudio::Model::OutputVariable.new('Surface Inside Face Temperature', model)
      var.setReportingFrequency('Timestep')

      var = OpenStudio::Model::OutputVariable.new('Zone Mean Air Temperature', model)
      var.setReportingFrequency('Timestep')

      var = OpenStudio::Model::OutputVariable.new('Zone Air System Sensible Cooling Rate', model)
      var.setReportingFrequency('Timestep')

      model.save(OpenStudio::Path.new(runDir + '/in.osm'), true)

      use_runmanager = true

      begin
        workflow = OpenStudio::WorkflowJSON.new
        use_runmanager = false
      rescue LoadError
        use_runmanager = true
      end

      sql_path = nil
      if use_runmanager == true

        co = OpenStudio::Runmanager::ConfigOptions.new(true)
        co.findTools(false, true, false, true)

        wf = OpenStudio::Runmanager::Workflow.new('modeltoidf->energypluspreprocess->energyplus')
        wf.add(co.getTools)
        job = wf.create(OpenStudio::Path.new(runDir), OpenStudio::Path.new(runDir + '/in.osm'), OpenStudio::Path.new(epwPath))

        rm = OpenStudio::Runmanager::RunManager.new
        rm.enqueue(job, true)
        rm.waitForFinished

      else

        osw_path = File.absolute_path(runDir + '/in.osw')

        workflow.setSeedFile(File.absolute_path(runDir + '/in.osm'))
        workflow.setWeatherFile(File.absolute_path(epwPath))
        workflow.saveAs(osw_path)

        cli_path = OpenStudio.getOpenStudioCLI
        cmd = "\"#{cli_path}\" run -w \"#{osw_path}\""
        puts cmd
        system(cmd)

        FileUtils.mkdir_p(File.dirname(workspacePath))
        FileUtils.cp(File.absolute_path(runDir + '/run/in.idf'), workspacePath)

        FileUtils.mkdir_p(File.dirname(sqlPath))
        FileUtils.cp(File.absolute_path(runDir + '/run/eplusout.sql'), sqlPath)

      end

    end
  end

  # delete output files
  def teardown
    # comment this out if you don't want to rerun EnergyPlus each time
    if File.exist?(sqlPath)
      # FileUtils.rm(sqlPath())
    end
  end

  # the actual test
  def test_ViewData_LastOSM_Hourly
    assert(File.exist?(modelPath))
    assert(File.exist?(workspacePath))
    assert(File.exist?(sqlPath))

    vt = OpenStudio::OSVersion::VersionTranslator.new
    model = vt.loadModel(modelPath)
    assert(model.is_initialized)
    model = model.get

    # create an instance of the measure
    measure = ViewData.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(numArguments, arguments.size)

    # create hash of argument values
    args_hash = {}
    args_hash['file_source'] = 'Last OSM'
    # args_hash["file_source"] = 'Last IDF'
    args_hash['reporting_frequency'] = 'Hourly'

    args_hash['variable1_name'] = 'Surface Outside Face Temperature'
    args_hash['variable2_name'] = 'Surface Inside Face Temperature'
    args_hash['variable3_name'] = 'Zone Mean Air Temperature'
    if Gem::Version.new(OpenStudio.openStudioVersion) > Gem::Version.new('3.6.1')
      args_hash['use_geometry_diagnostics'] = true
    end

    # args_hash["variable1_name"] = 'Zone Air System Sensible Cooling Rate'
    # args_hash["variable2_name"] = ''
    # args_hash["variable3_name"] = ''

    # args_hash["variable1_name"] = 'Surface Outside Face Temperature'
    # args_hash["variable2_name"] = 'Surface Outside Face Temperature'
    # args_hash["variable3_name"] = 'Surface Outside Face Temperature'

    # populate argument with specified hash value if specified
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # set up runner, this will happen automatically when measure is run in PAT
    runner.setLastOpenStudioModel(model)
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspacePath))
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sqlPath))

    current_dir = Dir.pwd
    out_dir = File.dirname(__FILE__) + '/output/LastOSM_Hourly'
    if !File.exist?(out_dir)
      FileUtils.mkdir_p(out_dir)
    end
    Dir.chdir(out_dir)

    # set argument values to good values and run the measure
    measure.run(runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 0)
    # assert(result.info.size == 1)

    Dir.chdir(current_dir)

    # load the output in http://threejs.org/editor/ to test
  end

  # the actual test
  def test_ViewData_LastIDF_Timestep
    assert(File.exist?(modelPath))
    assert(File.exist?(workspacePath))
    assert(File.exist?(sqlPath))

    vt = OpenStudio::OSVersion::VersionTranslator.new
    model = vt.loadModel(modelPath)
    assert(model.is_initialized)
    model = model.get

    # create an instance of the measure
    measure = ViewData.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(numArguments, arguments.size)

    # create hash of argument values
    args_hash = {}
    # args_hash["file_source"] = 'Last OSM'
    args_hash['file_source'] = 'Last IDF'
    args_hash['reporting_frequency'] = 'Timestep'

    args_hash['variable1_name'] = 'Surface Outside Face Temperature'
    args_hash['variable2_name'] = 'Surface Inside Face Temperature'
    args_hash['variable3_name'] = 'Zone Mean Air Temperature'
    if Gem::Version.new(OpenStudio.openStudioVersion) > Gem::Version.new('3.6.1')
      args_hash['use_geometry_diagnostics'] = false
    end

    # args_hash["variable1_name"] = 'Zone Air System Sensible Cooling Rate'
    # args_hash["variable2_name"] = ''
    # args_hash["variable3_name"] = ''

    # args_hash["variable1_name"] = 'Surface Outside Face Temperature'
    # args_hash["variable2_name"] = 'Surface Outside Face Temperature'
    # args_hash["variable3_name"] = 'Surface Outside Face Temperature'

    # populate argument with specified hash value if specified
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash[arg.name]
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # set up runner, this will happen automatically when measure is run in PAT
    runner.setLastOpenStudioModel(model)
    runner.setLastEnergyPlusWorkspacePath(OpenStudio::Path.new(workspacePath))
    runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sqlPath))

    current_dir = Dir.pwd
    out_dir = File.dirname(__FILE__) + '/output/LastIDF_Timestep'
    if !File.exist?(out_dir)
      FileUtils.mkdir_p(out_dir)
    end
    Dir.chdir(out_dir)

    # set argument values to good values and run the measure
    measure.run(runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == 'Success')
    # assert(result.warnings.size == 0)
    # assert(result.info.size == 1)

    Dir.chdir(current_dir)

    # load the output in http://threejs.org/editor/ to test
  end
end
