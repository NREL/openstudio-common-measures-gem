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

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# load OpenStudio measure libraries from openstudio-extension gem
require 'openstudio-extension'
require 'openstudio/extension/core/os_lib_helper_methods'

# start the measure
class GetSiteFromBuildingComponentLibrary < OpenStudio::Measure::ModelMeasure
  # resource file modules
  include OsLib_HelperMethods

  # human readable name
  def name
    return 'Get Site from Building Component Library'
  end

  # human readable description
  def description
    return 'Populate choice list from BCL, then selected site will be brought into model. This will include the weather file, design days, and water main temperatures.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'To start with measure will hard code a string to narrow the search. Then a shorter list than all weather files on BCL will be shown. In the future woudl be nice to select region based on climate zone set in building object.'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # Make argument for zipcode
    zipcode = OpenStudio::Measure::OSArgument.makeIntegerArgument('zipcode', true)
    zipcode.setDisplayName('Zip Code for project')
    zipcode.setDescription('Enter valid us 5 digit zipcode')
    zipcode.setDefaultValue(80401)
    args << zipcode

    # make an argument for use_upstream_args
    use_upstream_args = OpenStudio::Measure::OSArgument.makeBoolArgument('use_upstream_args', true)
    use_upstream_args.setDisplayName('Use Upstream Argument Values')
    use_upstream_args.setDescription('When true this will look for arguments or registerValues in upstream measures that match arguments from this measure, and will use the value from the upstream measure in place of what is entered for this measure.')
    use_upstream_args.setDefaultValue(true)
    args << use_upstream_args

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments(model))
    if !args then return false end

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

    # assign the user inputs to variables
    zipcode = args['zipcode']
    # validate that argument 5 digit number, but that doesn't mean it is valid zip code
    if zipcode > 100000
      runner.registerError('Requested number has too many digits, please just enter a 5 digit number')
      return false
    elsif zipcode < 10000
      # pad number
      zipcode = format('%05d', zipcode)
    else
      zipcode = zipcode.to_s
    end
    puts "zip code is #{zipcode}"

    # zipcode site lookup and download
    remote = OpenStudio::RemoteBCL.new

    # removed openstudio search in place of direct bcl api search. Still use remote to download commont once uuid is identified
    #     responses = remote.searchComponentLibrary("location:#{zipcode}", "Site")
    #     uid = nil
    #     responses.each_with_index do |response,i|
    #       # list results for diagnostic purposes
    #       runner.registerInfo("Response #{i} is #{response.name}")
    #       next if not response.name.include?("TMY3")
    #       next if not uid.nil?
    #       uid = response.uid
    #     end
    #     if uid.nil? then uid = responses.first.uid end

    # search bcl for site components for target zip code
    require 'open-uri'
    require 'json'

    # dev search string for internal testing
    # search_string = "http://bcl7.development.nrel.gov/api/search/location:'#{zipcode}'.json?fq[]=bundle:nrel_component&fq[]=sm_vid_Component_Tags:Site&api_version=2.0"

    # udpated to use https vs. http
    search_string = "https://bcl.nrel.gov/api/search/location:'#{zipcode}'.json?fq[]=bundle:nrel_component&fq[]=sm_vid_Component_Tags:Site&api_version=2.0"

    runner.registerInfo(search_string)
    # briefly I needed ssl_verify_mode:0 but now it seems to work again without it
    # responses = open(search_string,{ssl_verify_mode:0}).read
    responses = open(search_string).read
    responses = JSON.parse(responses)

    bcl_search_results = []
    bcl_search_rejected = []
    responses['result'].each do |i|
      reject = false

      i.each do |k, v|
        hash = {}
        hash['name'] = v['name']
        hash['tag'] = v['tags']['tag']
        hash['uuid'] = v['uuid']

        v['attributes']['attribute'].each do |j|
          if j['name'] == 'Latitude'
            hash['Latitude'] = j['value']
          elsif j['name'] == 'Longitude'
            hash['Longitude'] = j['value']
          elsif j['name'] == 'OpenStudio Type'
            hash['OpenStudio Type'] = j['value']
          end
        end

        # filter out of not expected component type
        # if not hash['tag'] == ["Location-Dependent Component.Site"] then reject = true end

        # need extra filter because not all object of Component.Site map to OS:Site objects
        # if not hash['OpenStudio Type'] == "OS:Site" then reject = true end

        # filter out if not tmy3
        if !hash['name'].upcase.include?('TMY3') then reject = true end

        # add to array
        if reject
          bcl_search_rejected << hash
        else
          bcl_search_results << hash
        end
      end
    end

    if bcl_search_results.empty?

      # list rejected results for diagnostics
      bcl_search_rejected.each_with_index do |search_hash, i|
        runner.registerInfo("Rejected response #{i} is #{search_hash.inspect}")
      end

      runner.registerError("Didn't find any valid site components on BCL within search radius that had tmy3 epw, design days, and stat files.")
      return false
    end

    # for now error if results include Aberdeen, which has shown up in past on bad searches
    if bcl_search_results[0]['name'].include?('Aberdeen')
      runner.registerError('Confirm that search results are correct, may have picked first alphabetical components')
      return false
    end

    uid = bcl_search_results.first['uuid']
    runner.registerInfo("uid is #{uid}")
    remote.downloadComponent(uid)
    component = remote.waitForComponentDownload

    if component.empty?
      runner.registerError('Cannot find local component')
      return false
    end
    component = component.get

    # get epw file
    files = component.files('epw')
    if files.empty?
      runner.registerError('No epw file found')
      return false
    end
    epw_path = component.files('epw')[0]

    # parse epw file
    epw_file = OpenStudio::EpwFile.new(OpenStudio::Path.new(epw_path))
    puts epw_file

    # report initial condition of model
    if model.weatherFile.is_initialized && model.weatherFile.get.path.is_initialized
      runner.registerInitialCondition("Current weather file is #{model.weatherFile.get.path.get} km.")
    else
      runner.registerInitialCondition("The model doesn't have a weather file assigned.")
    end

    # OpenStudio is letting multiple site, waterMain and weatherFile objects in model, delete those if they exist along with design days
    # todo - add in test of model with site shading surfaces, and see if they are orphaned or associated with new site.
    model.getSite.remove
    model.getSiteWaterMainsTemperature.remove
    if model.weatherFile.is_initialized
      model.weatherFile.remove
    end
    model.getDesignDays.each(&:remove)

    # get osc file
    osc_files = component.files('osc')
    if osc_files.empty?
      runner.registerError('No osc file found')
      return false
    end
    osc_path = component.files('osc')[0]
    osc_file = OpenStudio::IdfFile.load(osc_path)
    vt = OpenStudio::OSVersion::VersionTranslator.new
    component_object = vt.loadComponent(OpenStudio::Path.new(osc_path))

    # load os file
    if component_object.empty?
      runner.registerError("Cannot load construction component '#{osc_file}'")
      return false
    else
      object = component_object.get.primaryObject
      if object.to_Site.empty?
        runner.registerError("Component '#{osc_file}' does not include a site object")
        return false
      else
        componentData = model.insertComponent(component_object.get)
        if componentData.empty?
          runner.registerError("Failed to insert component '#{osc_file}' into model")
          return false
        else
          new_site_object = componentData.get.primaryComponentObject.to_Site.get
          runner.registerInfo("added site object named #{new_site_object.name}")
          site_water_main_temp = model.getSiteWaterMainsTemperature
          if site_water_main_temp.annualAverageOutdoorAirTemperature.is_initialized && site_water_main_temp.maximumDifferenceInMonthlyAverageOutdoorAirTemperatures.is_initialized
            avg_temp = site_water_main_temp.annualAverageOutdoorAirTemperature.get
            max_diff_monthly_avg_temp = site_water_main_temp.maximumDifferenceInMonthlyAverageOutdoorAirTemperatures.get
            avg_temp_ip = OpenStudio.convert(avg_temp, 'C', 'F').get
            max_diff_monthly_avg_temp_ip = OpenStudio.convert(max_diff_monthly_avg_temp, 'C', 'F').get
            runner.registerInfo("SiteWaterMainsTemperature object has Annual Avg. Outdoor Air Temp. of #{avg_temp_ip.round(2)} and Max. Diff. in Monthly Avg. Outdoor Air Temp. of #{max_diff_monthly_avg_temp_ip.round(2)}.")
          else
            runner.registerWarning('SiteWaterMainsTemperature object is missing Annual Avg. Outdoor Air Temp. or Max. Diff.in Monthly Avg. Outdoor Air Temp. set.')
          end
          if !model.getDesignDays.empty?
            runner.registerInfo("The model has #{model.getDesignDays.size} DesignDay objects")
          else
            runner.registerWarning("The model has #{model.getDesignDays.size} DesignDay objects")
          end

        end
      end
    end

    # get epw file
    epw_files = component.files('epw')
    if files.empty?
      runner.registerError('No epw file found')
      return false
    end
    epw_path = component.files('epw')[0]

    # parse epw file
    epw_file = OpenStudio::EpwFile.new(OpenStudio::Path.new(epw_path))

    # set weather file (this sets path to BCL diretory vs. temp zip file without this)
    OpenStudio::Model::WeatherFile.setWeatherFile(model, epw_file)

    # get stat file
    stat_path = OpenStudio::Path.new(component.files('stat')[0])
    text = nil
    File.open(component.files('stat')[0]) do |f|
      text = f.read.force_encoding('iso-8859-1')
    end

    # Get Climate zone.
    # - Climate type "3B" (ASHRAE Standard 196-2006 Climate Zone)**
    # - Climate type "6A" (ASHRAE Standards 90.1-2004 and 90.2-2004 Climate Zone)**
    regex = /Climate type \"(.*?)\" \(ASHRAE Standards?(.*)\)\*\*/
    match_data = text.match(regex)
    if match_data.nil?
      runner.registerWarning("Can't find ASHRAE climate zone in stat file.")
    else
      climate_zone = match_data[1].to_s.strip
      standard = match_data[2].to_s.strip # could confirm it is 196-2006 Climate Zone
      model.getClimateZones.clear
      model.getClimateZones.setClimateZone('ASHRAE', climate_zone)
      runner.registerInfo("Setting ASHRAE Climate Zone to #{climate_zone}")
    end

    # report final condition of model
    if model.weatherFile.is_initialized && model.weatherFile.get.path.is_initialized
      runner.registerFinalCondition("Current weather file is #{model.weatherFile.get.path.get}")
    else
      runner.registerFinalCondition("The model doesn't have a weather file assigned.")
    end

    return true
  end
end

# register the measure to be used by the application
GetSiteFromBuildingComponentLibrary.new.registerWithApplication
