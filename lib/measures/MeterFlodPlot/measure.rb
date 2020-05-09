

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

require 'erb'

# start the measure
class MeterFloodPlot < OpenStudio::Measure::ReportingMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'MeterFloodPlot'
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for the meter name
    meter_name = OpenStudio::Measure::OSArgument.makeStringArgument('meter_name', true)
    meter_name.setDisplayName('Enter Meter Name.')
    meter_name.setDefaultValue('Electricity:Facility') # you can find all possible variable names in the .rdd or .edd file
    args << meter_name

    return args
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments, user_arguments)
      return false
    end

    # assign the user inputs to variables
    meter_name = runner.getStringArgumentValue('meter_name', user_arguments)

    # check the user_name for reasonableness
    if meter_name == ''
      runner.registerError('No meter name was entered.')
      return false
    end

    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get

    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError('Cannot find last sql file.')
      return false
    end
    sqlFile = sqlFile.get
    model.setSqlFile(sqlFile)

    def neat_numbers(number, roundto = 2) # round to 0 or 2)
      # round to zero or two decimals
      if roundto == 2
        number = format '%.2f', number
      else
        number = number.round
      end
      # regex to add commas
      number.to_s.reverse.gsub(/([0-9]{3}(?=([0-9])))/, '\\1,').reverse
    end

    # unit conversion flag
    # this measure assumes tabular data comes in as si units, and only needs to be converted if user wants si
    units = 'ip' # expected values are "si" or "ip"

    # put data into variables, these are available in the local scope binding
    # define some timesteps that we'll use over and over
    zone_time_step = 'Zone Timestep'
    hourly_time_step = 'Hourly'
    hvac_time_step = 'HVAC System Timestep'

    # get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new('WeatherRunPeriod')
          ann_env_pd = env_pd
        end
      end
    end

    # array to store values, to find out min and max
    value_array = []

    # only try to get the annual timeseries if an annual simulation was run
    if ann_env_pd

      # get desired variable
      key_value = '' # when used should be in all caps. In this case I'm using a meter vs. an output variable, and it doesn't have a key
      output_timeseries = sqlFile.timeSeries(ann_env_pd, hourly_time_step, meter_name, key_value) # key value would go at the end if we used it.
      # loop through timeseries and move the data from an OpenStudio timeseries to a normal Ruby array (vector)
      if output_timeseries.is_initialized # checks to see if time_series exists
        output_hourly_plr = []
        output_timeseries = output_timeseries.get.values
        for i in 0..(output_timeseries.size - 1)

          temp_array = ['{value:', output_timeseries[i], ', hour:', i % 24, ', day:', (i / 24).round, '},']
          output_hourly_plr << temp_array.join
          value_array << output_timeseries[i]

        end

        # store min and max values
        min_value = value_array.min
        max_value = value_array.max

      else
        runner.registerWarning("Did not find hourly variable named #{meter_name}.  Cannot produce the requested plot.")
        return true
      end

    else
      runner.registerWarning('An annual simulation was not run.  Cannot get annual timeseries data')
      return true
    end

    value_range = ['{"low": ', min_value, ', "high": ', max_value, '}']

    # prepare data for report.html
    output_hourly_plr = output_hourly_plr.join
    value_range = value_range.join

    color_scale_values = []

    if units == 'si'
      scale_min = OpenStudio.convert(min_value, 'J', 'GJ').get
      scale_max = OpenStudio.convert(max_value, 'J', 'GJ').get
      scale_step = (scale_max - scale_min) / 7
      display_unit = 'GJ'
    else
      scale_min = OpenStudio.convert(min_value, 'J', 'kWh').get
      scale_max = OpenStudio.convert(max_value, 'J', 'kWh').get
      scale_step = (scale_max - scale_min) / 7
      display_unit = 'kWh'
    end

    color_scale_values << ['{"value": "', neat_numbers(scale_min + scale_step * 0), ' (', display_unit, ')"},'].join
    color_scale_values << ['{"value": "', neat_numbers(scale_min + scale_step * 1), ' (', display_unit, ')"},'].join
    color_scale_values << ['{"value": "', neat_numbers(scale_min + scale_step * 2), ' (', display_unit, ')"},'].join
    color_scale_values << ['{"value": "', neat_numbers(scale_min + scale_step * 3), ' (', display_unit, ')"},'].join
    color_scale_values << ['{"value": "', neat_numbers(scale_min + scale_step * 4), ' (', display_unit, ')"},'].join
    color_scale_values << ['{"value": "', neat_numbers(scale_min + scale_step * 5), ' (', display_unit, ')"},'].join
    color_scale_values << ['{"value": "', neat_numbers(scale_min + scale_step * 6), ' (', display_unit, ')"},'].join
    color_scale_values << ['{"value": "', neat_numbers(scale_min + scale_step * 7), ' (', display_unit, ')"},'].join
    color_scale_values = color_scale_values.join

    if key_value == ''
      plot_title = meter_name.to_s
    else
      plot_title = "#{meter_name}, #{key_value}"
    end

    if units == 'si'
      runner.registerInfo("Minimum value in dataset is #{neat_numbers(OpenStudio.convert(min_value, 'J', 'GJ'))} (MJ).")
      runner.registerInfo("Maximum value in dataset is #{neat_numbers(OpenStudio.convert(max_value, 'J', 'GJ'))} (MJ).")
    else
      runner.registerInfo("Minimum value in dataset is #{neat_numbers(OpenStudio.convert(min_value, 'J', 'kWh'))} (kWh).")
      runner.registerInfo("Maximum value in dataset is #{neat_numbers(OpenStudio.convert(max_value, 'J', 'kWh'))} (kWh).") end

    web_asset_path = OpenStudio.getSharedResourcesPath / OpenStudio::Path.new('web_assets')

    # reporting final condition
    runner.registerInitialCondition('Gathering data from EnergyPlus SQL file and OSM model.')

    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.in"
    if File.exist?(html_in_path)
      html_in_path = html_in_path
    else
      html_in_path = "#{File.dirname(__FILE__)}/report.html.in"
    end
    html_in = ''
    File.open(html_in_path, 'r') do |file|
      html_in = file.read
    end

    # configure template with variable values
    renderer = ERB.new(html_in)
    html_out = renderer.result(binding)

    # write html file
    html_out_path = './report.html'
    File.open(html_out_path, 'w') do |file|
      file << html_out
      # make sure data is written to the disk one way or the other
      begin
        file.fsync
      rescue StandardError
        file.flush
      end
    end

    # closing the sql file
    sqlFile.close

    # reporting final condition
    runner.registerFinalCondition("Generated #{html_out_path}.")

    return true
  end
end

# this allows the measure to be use by the application
MeterFloodPlot.new.registerWithApplication
