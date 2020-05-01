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
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class RadiantSlabWithDoasTest < Minitest::Test
  def load_model(osm_path)
    translator = OpenStudio::OSVersion::VersionTranslator.new
    model = translator.loadModel(OpenStudio::Path.new(osm_path))
    assert(!model.empty?)
    model = model.get
    return model
  end

  def run_dir(test_name)
    # always generate test output in specially named 'output' directory so result files are not made part of the measure
    return "#{File.dirname(__FILE__)}/output/#{test_name}"
  end

  def model_output_path(test_name)
    return "#{run_dir(test_name)}/#{test_name}.osm"
  end

  def sql_path(test_name)
    return "#{run_dir(test_name)}/run/eplusout.sql"
  end

  def report_path(test_name)
    return "#{run_dir(test_name)}/reports/eplustbl.html"
  end

  # applies the measure and then runs the model
  def apply_measure_and_run(test_name, measure, argument_map, osm_path, epw_path, run_model: false)
    assert(File.exist?(osm_path))
    assert(File.exist?(epw_path))

    # create run directory if it does not exist
    if !File.exist?(run_dir(test_name))
      FileUtils.mkdir_p(run_dir(test_name))
    end
    assert(File.exist?(run_dir(test_name)))

    # change into run directory for tests
    start_dir = Dir.pwd
    Dir.chdir run_dir(test_name)

    # remove prior runs if they exist
    if File.exist?(model_output_path(test_name))
      FileUtils.rm(model_output_path(test_name))
    end
    if File.exist?(report_path(test_name))
      FileUtils.rm(report_path(test_name))
    end

    # copy the osm and epw to the test directory
    new_osm_path = "#{run_dir(test_name)}/#{File.basename(osm_path)}"
    FileUtils.cp(osm_path, new_osm_path)
    new_epw_path = "#{run_dir(test_name)}/#{File.basename(epw_path)}"
    FileUtils.cp(epw_path, new_epw_path)
    # create an instance of a runner
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    # load the test model
    model = load_model(new_osm_path)

    # set model weather file
    epw_file = OpenStudio::EpwFile.new(OpenStudio::Path.new(new_epw_path))
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file)
    assert(model.weatherFile.is_initialized)

    # run the measure
    puts "\nAPPLYING MEASURE..."
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # save model
    model.save(model_output_path(test_name), true)

    if run_model && (result.value.valueName == 'Success')
      puts "\nRUNNING ANNUAL SIMULATION..."

      std = Standard.build('NREL ZNE Ready 2017')
      std.model_run_simulation_and_log_errors(model, run_dir(test_name))

      # check that the model ran successfully and generated a report
      assert(File.exist?(model_output_path(test_name)))
      assert(File.exist?(sql_path(test_name)))
      assert(File.exist?(report_path(test_name)))

      # set runner variables
      runner.setLastEpwFilePath(epw_path)
      runner.setLastOpenStudioModelPath(OpenStudio::Path.new(model_output_path(test_name)))
      runner.setLastEnergyPlusSqlFilePath(OpenStudio::Path.new(sql_path(test_name)))
      sql = runner.lastEnergyPlusSqlFile.get
      model.setSqlFile(sql)

      # test for unmet hours
      errs = []
      unmet_heating_hrs = std.model_annual_occupied_unmet_heating_hours(model)
      unmet_cooling_hrs = std.model_annual_occupied_unmet_cooling_hours(model)
      unmet_hrs = std.model_annual_occupied_unmet_hours(model)
      max_unmet_hrs = 550
      if unmet_hrs
        if unmet_hrs > 550
          errs << "For #{test_name} there were #{unmet_heating_hrs.round(1)} unmet occupied heating hours and #{unmet_cooling_hrs.round(1)} unmet occupied cooling hours (total: #{unmet_hrs.round(1)}), more than the limit of #{max_unmet_hrs}." if unmet_hrs > max_unmet_hrs
        else
          puts "There were #{unmet_heating_hrs.round(1)} unmet occupied heating hours and #{unmet_cooling_hrs.round(1)} unmet occupied cooling hours (total: #{unmet_hrs.round(1)})."
        end
      else
        errs << "For #{test_name} could not determine unmet hours; simulation may have failed."
      end
    end

    # change back directory
    Dir.chdir(start_dir)

    assert(errs.empty?, errs.join("\n"))

    return result
  end

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = RadiantSlabWithDoas.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(15, arguments.size)
    assert_equal('remove_existing_hvac', arguments[0].name)
    assert_equal('heating_plant_type', arguments[1].name)
    assert_equal('cooling_plant_type', arguments[2].name)
    assert_equal('waterside_economizer', arguments[3].name)
    assert_equal('radiant_type', arguments[4].name)
    assert_equal('include_carpet', arguments[5].name)
    assert_equal('control_strategy', arguments[6].name)
    assert_equal('proportional_gain', arguments[7].name)
    assert_equal('minimum_operation', arguments[8].name)
    assert_equal('switch_over_time', arguments[9].name)
    assert_equal('radiant_lockout', arguments[10].name)
    assert_equal('lockout_start_time', arguments[11].name)
    assert_equal('lockout_end_time', arguments[12].name)
    assert_equal('add_output_variables', arguments[13].name)
    assert_equal('standards_template', arguments[14].name)
  end

  def test_single_zone_office_5A_floor
    # this tests adding a fancoils with doas system to the model
    test_name = 'test_single_zone_office_5A_floor'
    puts "\n######\nTEST: #{test_name}\n######\n"
    osm_path = File.dirname(__FILE__) + '/single_zone_office_5A.osm'
    epw_path = File.dirname(__FILE__) + '/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw'

    # create an instance of the measure
    measure = RadiantSlabWithDoas.new

    # load the model; only used here for populating arguments
    model = load_model(osm_path)

    # set Arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # apply the measure to the model and optionally run the model
    result = apply_measure_and_run(test_name, measure, argument_map, osm_path, epw_path, run_model: true)

    # assert that it ran correctly
    assert(result.value.valueName == 'Success')
  end

  def test_single_zone_office_5A_ceiling
    # this tests adding a fancoils with doas system to the model
    test_name = 'test_single_zone_office_5A_ceiling'
    puts "\n######\nTEST: #{test_name}\n######\n"
    osm_path = File.dirname(__FILE__) + '/single_zone_office_5A.osm'
    epw_path = File.dirname(__FILE__) + '/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw'

    # create an instance of the measure
    measure = RadiantSlabWithDoas.new

    # load the model; only used here for populating arguments
    model = load_model(osm_path)

    # set Arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set arguments here; will vary by measure test
    radiant_type = arguments[4].clone
    assert(radiant_type.setValue('ceiling'))
    argument_map['radiant_type'] = radiant_type

    # apply the measure to the model and optionally run the model
    result = apply_measure_and_run(test_name, measure, argument_map, osm_path, epw_path, run_model: true)

    # assert that it ran correctly
    assert(result.value.valueName == 'Success')
  end

  def test_multi_zone_office_3C_floor
    # this tests adding a fancoils with doas system to the model
    test_name = 'test_multi_zone_office_3C_floor'
    puts "\n######\nTEST: #{test_name}\n######\n"
    osm_path = File.dirname(__FILE__) + '/multi_zone_office_3C.osm'
    epw_path = File.dirname(__FILE__) + '/USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw'

    # create an instance of the measure
    measure = RadiantSlabWithDoas.new

    # load the model; only used here for populating arguments
    model = load_model(osm_path)

    # set Arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # apply the measure to the model and optionally run the model
    result = apply_measure_and_run(test_name, measure, argument_map, osm_path, epw_path, run_model: true)

    # assert that it ran correctly
    assert(result.value.valueName == 'Success')
  end

  def test_multi_zone_office_3C_ceiling
    # this tests adding a fancoils with doas system to the model
    test_name = 'test_multi_zone_office_3C_ceiling'
    puts "\n######\nTEST: #{test_name}\n######\n"
    osm_path = File.dirname(__FILE__) + '/multi_zone_office_3C.osm'
    epw_path = File.dirname(__FILE__) + '/USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw'

    # create an instance of the measure
    measure = RadiantSlabWithDoas.new

    # load the model; only used here for populating arguments
    model = load_model(osm_path)

    # set Arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # set arguments here; will vary by measure test
    cooling_plant_type = arguments[2].clone
    assert(cooling_plant_type.setValue('Water Cooled Chiller'))
    argument_map['cooling_plant_type'] = cooling_plant_type

    waterside_economizer = arguments[3].clone
    assert(waterside_economizer.setValue('integrated'))
    argument_map['waterside_economizer'] = waterside_economizer

    radiant_type = arguments[4].clone
    assert(radiant_type.setValue('ceiling'))
    argument_map['radiant_type'] = radiant_type

    # apply the measure to the model and optionally run the model
    result = apply_measure_and_run(test_name, measure, argument_map, osm_path, epw_path, run_model: true)

    # assert that it ran correctly
    assert(result.value.valueName == 'Success')
  end
end
