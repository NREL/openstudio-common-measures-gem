#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

require 'json'
require 'time'

#start the measure
class RunPeriod < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Run Period Object"
  end

  # human readable description
  def description
    return "Set Run Period Object"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Set Run Period Object"
  end
  
  def year_month_day(str)
    result = nil
    if match_data = /(\d+)(\D)(\d+)(\D)(\d+)/.match(str)
      if match_data[1].size == 4 #yyyy-mm-dd
        year = match_data[1].to_i
        month = match_data[3].to_i
        day = match_data[5].to_i
        result = [year, month, day]
      elsif match_data[5].size == 4 #mm-dd-yyyy
        year = match_data[5].to_i
        month = match_data[1].to_i
        day = match_data[3].to_i
        result = [year, month, day]     
      end
    else
      puts "no match for '#{str}'"
    end
    return result
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #RunPeriodName
    runPeriodName = OpenStudio::Ruleset::OSArgument::makeStringArgument("runPeriodName",false)
    runPeriodName.setDisplayName("Run Period Name")
    runPeriodName.setDefaultValue("July")
    args << runPeriodName
    
    #make a start date argument
    start_date = OpenStudio::Ruleset::OSArgument::makeStringArgument("start_date",true)
    start_date.setDisplayName("Start date (yyyy-mm-dd or mm-dd-yyyy)")
    start_date.setDescription("Start date (yyyy-mm-dd or mm-dd-yyyy)")
    start_date.setDefaultValue("2015-7-25")
    args << start_date
    
    #make an end date argument
    end_date = OpenStudio::Ruleset::OSArgument::makeStringArgument("end_date",true)
    end_date.setDisplayName("End date (yyyy-mm-dd or mm-dd-yyyy)")
    end_date.setDescription("End date (yyyy-mm-dd or mm-dd-yyyy)")
    end_date.setDefaultValue("2015-7-26")
    args << end_date
    
    #daylightsavings
    daylightsavings = OpenStudio::Ruleset::OSArgument::makeBoolArgument("daylightsavings",false)
    daylightsavings.setDisplayName("Use Daylightsavings")
    daylightsavings.setDefaultValue(false)
    args << daylightsavings
    
    #holiday
    holiday = OpenStudio::Ruleset::OSArgument::makeBoolArgument("holiday",false)
    holiday.setDisplayName("Use Holiday and Special Days")
    holiday.setDefaultValue(false)
    args << holiday
    
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    runPeriodName = runner.getStringArgumentValue("runPeriodName",user_arguments)
    start_date = runner.getStringArgumentValue("start_date",user_arguments)
    end_date = runner.getStringArgumentValue("end_date",user_arguments)
    daylightsavings = runner.getBoolArgumentValue("daylightsavings",user_arguments)
    holiday = runner.getBoolArgumentValue("holiday",user_arguments)
    
    runPeriod = model.getRunPeriod()
    runPeriod.setName(runPeriodName)
    runPeriod.setUseWeatherFileDaylightSavings(daylightsavings)
    runPeriod.setUseWeatherFileHolidays(holiday)
    
    # set start date
    if date = year_month_day(start_date)

      start_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(date[1]), date[2], date[0])
      
      # actual year of start date
      yearDescription = model.getYearDescription()
      yearDescription.setCalendarYear(date[0])
           
      runPeriod.setBeginMonth(date[1])
      runPeriod.setBeginDayOfMonth(date[2])
    else
      runner.registerError("Unknown start date '#{start_date}'")
      fail "Unknown start date '#{start_date}'"
      return false
    end
    
    # set end date
    if date = year_month_day(end_date)
      
      end_date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(date[1]), date[2], date[0])
      
      runPeriod.setEndMonth(date[1])
      runPeriod.setEndDayOfMonth(date[2])
    else
      runner.registerError("Unknown end date '#{end_date}'")
      fail "Unknown end date '#{end_date}'"
      return false
    end
    
    runner.registerInfo("runperiod: #{runPeriod.to_s}")
    #reporting final condition of model
    runner.registerFinalCondition("Changed run period.")
    
    #set minimum warmup days
    #model.getSimulationControl.setMinimumNumberofWarmupDays(20)
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
RunPeriod.new.registerWithApplication