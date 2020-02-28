require 'erb'
require 'json'

require "#{File.dirname(__FILE__)}/resources/os_lib_reporting_envelope_and_internal_loads_breakdown"
require "#{File.dirname(__FILE__)}/resources/os_lib_helper_methods"

# start the measure
class EnvelopeAndInternalLoadBreakdown < OpenStudio::Ruleset::ReportingUserScript
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Envelope and Internal Load Breakdown"
  end
  # human readable description
  def description
    return "Report provides annual and monthly views into heat gains and losses for envelope and internal loads."
  end
  # human readable description of modeling approach
  def modeler_description
    return "It uses the following variables: Electric Equipment Total Heating Energy, Zone Lights Total Heating Energy, Zone, People Sensible Heating Energy, Surface Average Face Conduction Heat Transfer Energy, Surface Window Heat Gain Energy, Surface Window Heat Loss Energy, Zone Infiltration Sensible Heat Gain Energy, Zone Infiltration Sensible Heat Loss Energy. For Surface Average Face Conduction Heat Transfer Energy bin positive values as heat gain and negative values as heat loss.
"
  end
  def possible_sections

    # methods for sections in order that they will appear in report
    result = []

    # instead of hand populating, any methods with 'section' in the name will be added in the order they appear
    all_setions =  OsLib_ReportingHeatGainLoss.methods(false)
    all_setions.each do |section|
      next if not section.to_s.include? 'section'
      result << section.to_s
    end

    result
  end

  # define the arguments that the user will input
  def arguments
    args = OpenStudio::Ruleset::OSArgumentVector.new

=begin
    # populate arguments
    possible_sections.each do |method_name|
      # get display name
      arg = OpenStudio::Ruleset::OSArgument.makeBoolArgument(method_name, true)
      display_name = eval("OsLib_ReportingHeatGainLoss.#{method_name}(nil,nil,nil,true)[:title]")
      arg.setDisplayName(display_name)
      arg.setDefaultValue(true)
      args << arg
    end
=end

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
=begin
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Increase Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Increase Due to Overheating Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Decrease Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation No Load Heat Addition Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Air System Heat Exchanger Total Cooling Energy,monthly;').get
=end

    # monthly heat loss outputs
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Infiltration Sensible Heat Loss Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Surface Window Heat Loss Energy,monthly;').get
=begin
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Increase Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Increase Due to Overcooling Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Decrease Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation No Load Heat Removal Energy,monthly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Air System Heat Exchanger Total Heating Energy,monthly;').get

    # diagnostic outputs
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Increase Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Increase Due to Overheating Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Cooling Load Decrease Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation No Load Heat Addition Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Air System Heat Exchanger Total Cooling Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Increase Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Increase Due to Overcooling Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation Heating Load Decrease Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Mechanical Ventilation No Load Heat Removal Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Air System Heat Exchanger Total Heating Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Site Outdoor Air Drybulb Temperature,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Site Outdoor Air Wetbulb Temperature,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Air System Fan Air Electric Energy,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Air System Outdoor Air Mass Flow Rate,hourly;').get
    result << OpenStudio::IdfObject.load('Output:Variable,,Zone Air Terminal Outdoor Air Volume Flow Rate,hourly;').get
=end

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

=begin
    # assign the user inputs to variables
    args = OsLib_HelperMethods.createRunVariables(runner, model, user_arguments, arguments)
    unless args
      return false
    end
=end

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

      begin
        #next unless args[method_name]
        section = false
        eval("section = OsLib_ReportingHeatGainLoss.#{method_name}(model,sql_file,runner,false)")
        display_name = eval("OsLib_ReportingHeatGainLoss.#{method_name}(nil,nil,nil,true)[:title]")
        if section
          raw_sections << section
          sections_made += 1
          # look for emtpy tables and warn if skipped because returned empty
          section[:tables].each do |table|
            if not table
              runner.registerWarning("A table in #{display_name} section returned false and was skipped.")
              section[:messages] = ["One or more tables in #{display_name} section returned false and was skipped."]
            end
          end
        else
          runner.registerWarning("#{display_name} section returned false and was skipped.")
          section = {}
          section[:title] = "#{display_name}"
          section[:tables] = []
          section[:messages] = []
          section[:messages] << "#{display_name} section returned false and was skipped."
          raw_sections << section
        end
      rescue => e
        display_name = eval("OsLib_ReportingHeatGainLoss.#{method_name}(nil,nil,nil,true)[:title]")
        if display_name == nil then display_name == method_name end
        runner.registerWarning("#{display_name} section failed and was skipped because: #{e}. Detail on error follows.")
        runner.registerWarning("#{e.backtrace.join("\n")}")

        # add in section heading with message if section fails
        section = eval("OsLib_ReportingHeatGainLoss.#{method_name}(nil,nil,nil,true)")
        section[:messages] = []
        section[:messages] << "#{display_name} section failed and was skipped because: #{e}. Detail on error follows."
        section[:messages] << ["#{e.backtrace.join("\n")}"]
        raw_sections << section

      end

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
      rescue
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
