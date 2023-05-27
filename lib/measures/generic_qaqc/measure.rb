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

require 'erb'
require 'json'
require 'openstudio-standards'

# load OpenStudio measure libraries from openstudio-extension gem
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_schedules'
require 'openstudio/extension/core/os_lib_helper_methods'
require 'openstudio/extension/core/os_lib_model_generation.rb'

# require all .rb files in resources folder
Dir[File.dirname(__FILE__) + '/resources/*.rb'].each { |file| require file }

# start the measure
class GenericQAQC < OpenStudio::Measure::ReportingMeasure
  # all QAQC checks should be in OsLib_QAQC module
  include OsLib_QAQC
  include OsLib_HelperMethods
  include OsLib_ModelGeneration

  # OsLib_CreateResults is needed for utility EDA programs but not the generic QAQC measure
  # include OsLib_CreateResults

  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'Generic QAQC'
  end

  # human readable description
  def description
    return 'This measure extracts key simulation results and performs basic model QAQC checks. Each category of checks provides a description of the source of the check. In some cases the target standards and tollerances are adjustable.'
  end

  # human readable description of modeling approach
  def modeler_description
    return "Reads the model and sql file to pull out the necessary information and run the model checks.  The check results show up as warning messages in the measure's output on the PAT run tab."
  end

  def possible_check_categories
    results = []

    # gather options_check_weather_files (example data below not used since check_weather_files commented out for generic QAQC)
    options_check_weather_files = {}
    epw_ch_01 = {}
    epw_ch_01['climate_zone'] = '5B'
    options_check_weather_files['USA_CO_Golden-NREL.724666_TMY3.epw'] = epw_ch_01
    epw_ch_01['summer'] = []
    epw_ch_01['summer'] << 'Denver Centennial  Golden   N Ann Clg .4% Condns DB=>MWB'
    epw_ch_01['summer'] << 'Denver Centennial  Golden   N Ann Clg .4% Condns DP=>MDB'
    epw_ch_01['summer'] << 'Denver Centennial  Golden   N Ann Clg .4% Condns Enth=>MDB'
    epw_ch_01['summer'] << 'Denver Centennial  Golden   N Ann Clg .4% Condns WB=>MDB'
    epw_ch_01['winter'] = []
    epw_ch_01['winter'] << 'Denver Centennial  Golden   N Ann Htg 99.6% Condns DB'
    epw_ch_01['winter'] << 'Denver Centennial  Golden   N Ann Htg Wind 99.6% Condns WS=>MCDB'
    epw_ch_01['winter'] << 'Denver Centennial  Golden   N Ann Hum_n 99.6% Condns DP=>MCDB'
    # add additional weather with design day objects as required

    # gather inputs for check_mech_sys_capacity. Each option has a target value, min and max fractional tolerance, and units
    # in the future climate zone specific targets may be in standards
    # todo - expose these tollerances as user arguments
    options_check_mech_sys_capacity = {}
    options_check_mech_sys_capacity['chiller_max_flow_rate'] = { 'target' => 2.4, 'min' => 0.1, 'max' => 0.1, 'units' => 'gal/ton*min' }
    options_check_mech_sys_capacity['air_loop_max_flow_rate'] = { 'target' => 1.0, 'min' => 0.1, 'max' => 0.1, 'units' => 'cfm/ft^2' }
    options_check_mech_sys_capacity['air_loop_cooling_capacity'] = { 'target' => 0.0033, 'min' => 0.1, 'max' => 0.1, 'units' => 'tons/ft^2' }
    options_check_mech_sys_capacity['zone_heating_capacity'] = { 'target' => 12.5, 'min' => 0.20, 'max' => 0.40, 'units' => 'Btu/ft^2*h' }

    # results << {:method_name => 'check_weather_files',:cat => 'General',:standards => false,:data => options_check_weather_files,:min_tol => false,:max_tol => false, :units => nil}
    results << { method_name: 'check_eui_reasonableness', cat: 'General', standards: true, data: nil, tol_min: 0.1, tol_max: true, units: 'fraction' }
    results << { method_name: 'check_eui_by_end_use', cat: 'General', standards: true, data: nil, tol_min: 0.25, tol_max: true, units: 'fraction' }
    results << { method_name: 'check_mech_sys_part_load_eff', cat: 'General', standards: true, data: nil, tol_min: 0.05, tol_max: true, units: 'fraction' }
    results << { method_name: 'check_mech_sys_capacity', cat: 'General', standards: true, data: options_check_mech_sys_capacity, tol_min: false, tol_max: false, units: 'fraction' }
    results << { method_name: 'check_simultaneous_heating_and_cooling', cat: 'General', standards: false, data: nil, tol_min: false, tol_max: 0.05, units: 'fraction' }
    results << { method_name: 'check_internal_loads', cat: 'Baseline', standards: true, data: nil, tol_min: 0.1, tol_max: true, units: 'fraction' }
    results << { method_name: 'check_schedules', cat: 'Baseline', standards: true, data: nil, tol_min: 0.05, tol_max: true, units: 'fraction' }
    results << { method_name: 'check_envelope_conductance', cat: 'Baseline', standards: true, data: nil, tol_min: 0.1, tol_max: true, units: 'fraction' }
    results << { method_name: 'check_domestic_hot_water', cat: 'Baseline', standards: true, data: nil, tol_min: 0.25, tol_max: true, units: 'fraction' }
    results << { method_name: 'check_mech_sys_efficiency', cat: 'Baseline', standards: true, data: nil, tol_min: 0.1, tol_max: true, units: 'fraction' }
    results << { method_name: 'check_mech_sys_type', cat: 'Baseline', standards: true, data: nil, tol_min: false, tol_max: false, units: nil }
    results << { method_name: 'check_supply_air_and_thermostat_temp_difference', cat: 'Baseline', standards: true, data: nil, tol_min: 0.5, tol_max: false, units: 'F' }

    results
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Make an argument for the template
    template = OpenStudio::Measure::OSArgument.makeChoiceArgument('template', get_doe_templates(false), true)
    template.setDisplayName('Target ASHRAE Standard')
    template.setDescription('This used to set the target standard for most checks.')
    template.setDefaultValue('90.1-2013') # there is override variable in run method for this
    args << template

    # add arguments from possible_check_categories
    possible_check_categories.each do |hash|
      cat = hash[:cat]
      cat_input = "\'#{cat}\'"
      if hash[:standards]
        standards_input = ",\'selected ASHRAE standard\'"
      else
        standards_input = ''
      end
      if hash[:data].nil?
        data_input = ''
      else
        data_input = ",#{hash[:data]}"
      end
      if !hash[:tol_min]
        min = nil
        min_input = ''
      else
        min = hash[:tol_min]
        min_input = ",#{min}"
      end
      if hash[:tol_max].is_a? Float
        max = hash[:tol_max]
        max_input = ",#{max}"
      elsif !hash[:tol_max]
        max = nil
        max_input = ''
      else
        max = hash[:tol_min]
        max_input = ",#{max}"
      end

      name_cat_desc = eval("#{hash[:method_name]}(#{cat_input}#{data_input}#{standards_input}#{min_input}#{max_input},true)")
      arg = OpenStudio::Measure::OSArgument.makeBoolArgument(hash[:method_name], true)
      arg.setDisplayName("#{name_cat_desc[0]} (#{hash[:cat]})")
      arg.setDescription(name_cat_desc[2])
      arg.setDefaultValue(true)
      args << arg
      if !min.nil?
        arg_tol = OpenStudio::Measure::OSArgument.makeDoubleArgument("#{hash[:method_name]}_tol", true)
        arg_tol.setDisplayName("#{name_cat_desc[0]} Tolerance")
        arg_tol.setDefaultValue(min)
        arg_tol.setUnits(hash[:units])
        args << arg_tol
      end
      if hash[:tol_max].is_a? Float
        arg_max_tol = OpenStudio::Measure::OSArgument.makeDoubleArgument("#{hash[:method_name]}_max_tol", true)
        arg_max_tol.setDisplayName("#{name_cat_desc[0]} Max Tolerance")
        arg_max_tol.setDefaultValue(max)
        arg_max_tol.setUnits(hash[:units])
        args << arg_max_tol
      end
    end

    # make an argument for use_upstream_args
    use_upstream_args = OpenStudio::Measure::OSArgument.makeBoolArgument('use_upstream_args', true)
    use_upstream_args.setDisplayName('Use Upstream Argument Values')
    use_upstream_args.setDescription('When true this will look for arguments or registerValues in upstream measures that match arguments from this measure, and will use the value from the upstream measure in place of what is entered for this measure.')
    use_upstream_args.setDefaultValue(true)
    args << use_upstream_args

    return args
  end # end the arguments method

  # return a vector of IdfObject's to request EnergyPlus objects needed by the run method
  def energyPlusOutputRequests(runner, user_arguments)
    super(runner, user_arguments)

    result = OpenStudio::IdfObjectVector.new

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, @model, user_arguments, arguments)
    unless args
      return false
    end

    # only add terminalvariables if that check is enabled
    if args['check_simultaneous_heating_and_cooling']
      # get the last model
      model = runner.lastOpenStudioModel
      if model.empty?
        runner.registerError('Cannot find last model.')
        return false
      end
      model = model.get

      # Request the terminal reheat coil and
      # terminal cooling rates for every VAV
      # reheat terminal.
      model.getAirTerminalSingleDuctVAVReheats.each do |term|
        # Reheat coil heating rate
        rht_coil = term.reheatCoil
        result << OpenStudio::IdfObject.load("Output:Variable,#{rht_coil.name},Heating Coil Heating Rate,Hourly;").get
        result << OpenStudio::IdfObject.load("Output:Variable,#{rht_coil.name},Heating Coil Air Heating Rate,Hourly;").get

        # Zone Air Terminal Sensible Heating Rate
        result << OpenStudio::IdfObject.load("Output:Variable,ADU #{term.name},Zone Air Terminal Sensible Cooling Rate,Hourly;").get
      end
    end

    return result
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # make the runner a class variable
    @runner = runner

    # if true errors on QAQC sections will show full backtrace. Use for diagnostics
    @error_backtrace = true

    # register initial condition
    runner.registerInitialCondition('Starting QAQC report generation')

    # get sql, model, and web assets
    setup = OsLib_Reporting.setup(runner)
    unless setup
      return false
    end
    @model = setup[:model]
    # workspace = setup[:workspace]
    @sql = setup[:sqlFile]
    web_asset_path = setup[:web_asset_path]

    # temp code to address climate zone problem mentioned in OpenStudio issue# 3148
    climateZones = @model.getClimateZones
    cz = climateZones.getClimateZones('ASHRAE').first.value
    climateZones.clear
    climateZones.setClimateZone('ASHRAE', cz)

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, @model, user_arguments, arguments)
    unless args
      return false
    end

    # vector to store the results and checks
    report_elems = OpenStudio::AttributeVector.new

    # used for edapt programs to populate xml file with extra data
    # report_elems << create_results

    # lookup and replace argument values from upstream measures
    if args['use_upstream_args'] == true
      args.each do |arg, value|
        next if arg == 'use_upstream_args' # this argument should not be changed
        value_from_osw = OsLib_HelperMethods.check_upstream_measure_for_arg(runner, arg)
        if !value_from_osw.empty?
          runner.registerInfo("Replacing argument named #{arg} from current measure with a value of #{value_from_osw[:value]} from #{value_from_osw[:measure_name]}.")
          new_val = value_from_osw[:value]
          # TODO: - make code to handle non strings more robust. check_upstream_measure_for_arg coudl pass bakc the argument type
          if arg == 'total_bldg_floor_area'
            args[arg] = new_val.to_f
          elsif arg == 'num_stories_above_grade'
            args[arg] = new_val.to_f
          elsif arg == 'zipcode'
            args[arg] = new_val.to_i
          else
            args[arg] = new_val
          end
        end
      end
    end

    # utility name to to used by some qaqc checks
    @utility_name = nil # for utility QAQC string is passed in
    default_target_standard = args['template'] # for utility QAQC this is hard coded, for generic it is user argument

    # get building type, different standards path if multifamily
    building_type = ''
    if @model.getBuilding.standardsBuildingType.is_initialized
      building_type = @model.getBuilding.standardsBuildingType.get
    end

    # create an attribute vector to hold the checks
    check_elems = OpenStudio::AttributeVector.new

    # loop through QAQC categories where bool is true
    possible_check_categories.each do |hash|
      # skip if bool arg for this method is false
      next if args[hash[:method_name]] == false

      cat = hash[:cat]
      cat_input = "\'#{cat}\'"
      if hash[:standards]
        standards_input = ",\'#{default_target_standard}\'"
      else
        standards_input = ''
      end
      if hash[:data].nil?
        data_input = ''
      else
        data_input = ",#{hash[:data]}"
      end

      # get min tol
      if args.key?("#{hash[:method_name]}_tol")
        # get tol value
        tol = args["#{hash[:method_name]}_tol"]
        # set min inputs
        if tol.is_a? Float
          min_input = ",#{tol}"
        else
          min_input = ''
        end
      else
        min_input = ''
      end

      # get max tol
      if args.key?("#{hash[:method_name]}_max_tol")
        # get tol value
        max_tol = args["#{hash[:method_name]}_max_tol"]
        # set max inputs
        if max_tol.is_a? Float
          max_input = ",#{max_tol}"
        elsif (hash[:tol_max] == true) && hash[:tol_min].is_a?(Float)
          # if true then use double from min_tol
          max_input = ",#{args["#{hash[:method_name]}_tol"]}"
        else
          max_input = ''
        end
      else
        if (hash[:tol_max] == true) && hash[:tol_min].is_a?(Float)
          # if true then use double from min_tol
          max_input = ",#{args["#{hash[:method_name]}_tol"]}"
        else
          max_input = ''
        end
      end

      # run QAQC check
      eval("check_elems << #{hash[:method_name]}(#{cat_input}#{data_input}#{standards_input}#{min_input}#{max_input},false)")
    end

    # add checks to report_elems
    report_elems << OpenStudio::Attribute.new('checks', check_elems)

    # create an extra layer of report.  the first level gets thrown away.
    top_level_elems = OpenStudio::AttributeVector.new
    top_level_elems << OpenStudio::Attribute.new('report', report_elems)

    # create the report
    result = OpenStudio::Attribute.new('summary_report', top_level_elems)
    result.saveToXml(OpenStudio::Path.new('report.xml'))

    # closing the sql file
    @sql.close

    # reporting final condition
    runner.registerFinalCondition('Finished generating report.xml.')

    # populate sections using attributes
    sections = OsLib_Reporting.sections_from_check_attributes(check_elems, runner)

    # generate html output
    OsLib_Reporting.gen_html("#{File.dirname(__FILE__)}report.html.erb", web_asset_path, sections, name)

    return true
  end # end the run method
end # end the measure

# this allows the measure to be use by the application
GenericQAQC.new.registerWithApplication
