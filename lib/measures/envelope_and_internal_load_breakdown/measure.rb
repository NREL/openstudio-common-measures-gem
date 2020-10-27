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
require 'json'

# load OpenStudio measure libraries from openstudio-extension gem
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'

require "#{File.dirname(__FILE__)}/resources/os_lib_reporting_envelope_and_internal_loads_breakdown"

# start the measure
class EnvelopeAndInternalLoadBreakdown < OpenStudio::Ruleset::ReportingUserScript
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'Envelope and Internal Load Breakdown'
  end

  # human readable description
  def description
    return 'Report provides annual and monthly views into heat gains and losses for envelope and internal loads.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "It uses the following variables: Electric Equipment Total Heating Energy, Zone Lights Total Heating Energy, Zone, People Sensible Heating Energy, Surface Average Face Conduction Heat Transfer Energy, Surface Window Heat Gain Energy, Surface Window Heat Loss Energy, Zone Infiltration Sensible Heat Gain Energy, Zone Infiltration Sensible Heat Loss Energy. For Surface Average Face Conduction Heat Transfer Energy bin positive values as heat gain and negative values as heat loss.\n"
  end

  def possible_sections
    # methods for sections in order that they will appear in report
    result = []

    # instead of hand populating, any methods with 'section' in the name will be added in the order they appear
    all_sections = OsLib_ReportingHeatGainLoss.methods(false)
    method_hash = {}
    all_sections.each do |section|
      next if !section.to_s.include? 'section'
      method_hash[section.to_s] = OsLib_ReportingHeatGainLoss.method(section).source_location.last
    end
    # sort methods by location in file (this was not necessary when using Ruby 2.2.4)
    result = method_hash.sort_by { |_key, value| value }.to_h.keys

    result
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Ruleset::OSArgumentVector.new

    #     # populate arguments
    #     possible_sections.each do |method_name|
    #       # get display name
    #       arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument(method_name, true)
    #       display_name = eval("OsLib_ReportingHeatGainLoss.#{method_name}(nil,nil,nil,true)[:title]")
    #       arg.setDisplayName(display_name)
    #       arg.setDefaultValue(true)
    #       args << arg
    #     end

    args
  end

  # add any outout variable requests here
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    # monthly heat gain outputs
    result << OpenStudio::IdfObject.load('Output:Variable,,Electric Equipment Total Heating Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Gas Equipment Total Heating Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Lights Total Heating Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone People Sensible Heating Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Infiltration Sensible Heat Gain Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Surface Window Heat Gain Energy,monthly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Increase Energy,monthly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Increase Due to Overheating Energy,monthly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Decrease Energy,monthly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation No Load Heat Addition Energy,monthly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Air System Heat Exchanger Total Cooling Energy,monthly;').get

    # monthly heat loss outputs
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Infiltration Sensible Heat Loss Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Surface Window Heat Loss Energy,monthly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Increase Energy,monthly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Increase Due to Overcooling Energy,monthly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Decrease Energy,monthly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation No Load Heat Removal Energy,monthly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Air System Heat Exchanger Total Heating Energy,monthly;').get
    #
    #     # diagnostic outputs
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Increase Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Increase Due to Overheating Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Decrease Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation No Load Heat Addition Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Air System Heat Exchanger Total Cooling Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Increase Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Increase Due to Overcooling Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Decrease Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation No Load Heat Removal Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Air System Heat Exchanger Total Heating Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Site Outdoor Air Drybulb Temperature,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Site Outdoor Air Wetbulb Temperature,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Air System Fan Air Electric Energy,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Air System Outdoor Air Mass Flow Rate,hourly;').get
    #     result << OpenStudio::IdfObject.load('Output:Variable,,Zone Air Terminal Outdoor Air Volume Flow Rate,hourly;').get

    # hourly outputs (will bin by hour to heat loss or gain and roll up to monthly, may break out by surface type)
    result << OpenStudio::IdfObject.load('Output:Variable,,Surface Average Face Conduction Heat Transfer Energy,hourly;').get

    result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # get sql, model, and web assets
    setup = OsLib_ReportingHeatGainLoss.setup(runner)
    unless setup
      return false
    end
    model = setup[:model]
    # workspace = setup[:workspace]
    sql_file = setup[:sqlFile]
    web_asset_path = setup[:web_asset_path]

    #     # assign the user inputs to variables
    #     args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments)
    #     unless args
    #       return false
    #     end

    # reporting final condition
    runner.registerInitialCondition('Gathering data from EnergyPlus SQL file and OSM model.')

    # pass measure display name to erb
    @name = name

    # create a array of sections to loop through in erb file
    @sections = []
    raw_sections = []

    # generate data for requested sections
    sections_made = 0
    possible_sections.each do |method_name|
      # next unless args[method_name]
      section = false
      eval("section = OsLib_ReportingHeatGainLoss.#{method_name}(model,sql_file,runner,false)")
      display_name = eval("OsLib_ReportingHeatGainLoss.#{method_name}(nil,nil,nil,true)[:title]")
      if section
        raw_sections << section
        sections_made += 1
        # look for emtpy tables and warn if skipped because returned empty
        section[:tables].each do |table|
          if !table
            runner.registerWarning("A table in #{display_name} section returned false and was skipped.")
            section[:messages] = ["One or more tables in #{display_name} section returned false and was skipped."]
          end
        end
      else
        runner.registerWarning("#{display_name} section returned false and was skipped.")
        section = {}
        section[:title] = display_name.to_s
        section[:tables] = []
        section[:messages] = []
        section[:messages] << "#{display_name} section returned false and was skipped."
        raw_sections << section
      end
    rescue StandardError => e
      display_name = eval("OsLib_ReportingHeatGainLoss.#{method_name}(nil,nil,nil,true)[:title]")
      if display_name.nil? then display_name == method_name end
      runner.registerWarning("#{display_name} section failed and was skipped because: #{e}. Detail on error follows.")
      runner.registerWarning(e.backtrace.join("\n").to_s)

      # add in section heading with message if section fails
      section = eval("OsLib_ReportingHeatGainLoss.#{method_name}(nil,nil,nil,true)")
      section[:messages] = []
      section[:messages] << "#{display_name} section failed and was skipped because: #{e}. Detail on error follows."
      section[:messages] << [e.backtrace.join("\n").to_s]
      raw_sections << section
    end

    # reorganize section order so summaries are at top (1,3,0,2)
    @sections << raw_sections[1]
    @sections << raw_sections[3]
    @sections << raw_sections[0]
    @sections << raw_sections[2]

    # read in template
    html_in_path = "#{File.dirname(__FILE__)}/resources/report.html.erb"
    if File.exist?(html_in_path)
      html_in_path = html_in_path
    else
      html_in_path = "#{File.dirname(__FILE__)}/report.html.erb"
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
    sql_file.close

    # reporting final condition
    runner.registerFinalCondition("Generated report with #{sections_made} sections to #{html_out_path}.")

    true
  end
end

# this allows the measure to be use by the application
EnvelopeAndInternalLoadBreakdown.new.registerWithApplication
