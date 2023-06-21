# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# start the measure
class AddZoneMixingObject < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    return 'Add Zone Mixing Object'
  end

  # human readable description
  def description
    return 'This adds a zone mixing object with a few inputs exposed, including source zone. You can add multiple copies of this to the workflow as needed.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Currently this is just setup for design level calculation method, but it could be extended as needed..'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # the name of the zone to receive air
    zone_name = OpenStudio::Measure::OSArgument.makeStringArgument('zone_name', true)
    zone_name.setDisplayName('Zone with Exhaust')
    args << zone_name

    # the name of the schedule
    schedule_name = OpenStudio::Measure::OSArgument.makeStringArgument('schedule_name', true)
    schedule_name.setDisplayName('Schedule Name for Zone Mixing')
    args << schedule_name

    # design level for zone mixing
    design_level = OpenStudio::Measure::OSArgument.makeDoubleArgument('design_level', true)
    design_level.setDisplayName('Design Level for Zone Mixing')
    design_level.setUnits('cfm')
    args << design_level

    # the name of the zone to receive air
    source_zone_name = OpenStudio::Measure::OSArgument.makeStringArgument('source_zone_name', true)
    source_zone_name.setDisplayName('Source Zone for Zone Mixing')
    args << source_zone_name

    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    zone_name = runner.getStringArgumentValue('zone_name', user_arguments)
    schedule_name = runner.getStringArgumentValue('schedule_name', user_arguments)
    design_level = runner.getDoubleArgumentValue('design_level', user_arguments)
    source_zone_name = runner.getStringArgumentValue('source_zone_name', user_arguments)

    # reporting initial condition of model
    zone_mixing_objects = workspace.getObjectsByType('ZoneMixing'.to_IddObjectType)
    runner.registerInitialCondition("The building started with #{zone_mixing_objects.size} zone mixing objects.")

    # get all thermal zones in the starting model
    zones = workspace.getObjectsByType('Zone'.to_IddObjectType)

    # validate input names and get zones
    zone_name_valid = false
    source_zone_name_valid = false
    zones.each do |zone|
      if zone_name == zone.getString(0).to_s
        zone_name_valid = true
      elsif source_zone_name == zone.getString(0).to_s
        source_zone_name_valid = true
      end
    end

    # error if didn't find zones
    if (zone_name_valid == false) || (source_zone_name_valid == false)
      runner.registerError('One or more of the expected zones could not be found..')
      return false
    end

    # TODO: - validate schedule name (multiple types to look at)

    # validate design level input
    if design_level < 0.0
      runner.registerError('Choose a non negative number for design level.')
      return false
    end
    # variables for zone mixing object
    zm_calc_method = 'Flow/Zone' # at some point in the future could add more options and inputs for this
    design_level_si = OpenStudio.convert(design_level, 'cfm', 'm^3/s').get

    # add a new zone mixing to the model
    zone_mixing_string = "
      ZoneMixing,
        #{zone_name} Zone Mixing,  !- Name
        #{zone_name},  !- Zone Name
        #{schedule_name},  !- Schedule Name
        #{zm_calc_method},  !- Design Flow Rate Calculation Method
        #{design_level_si},  !- Design Level
        ,  !- Volume Flow Rate per Area {m3/s/m2}
        ,  !- Volume Flow Rate Per Person {m3/s/person}
        ,  !- Air Changes per Hour {ACH}
        #{source_zone_name},  !- Source Zone Name
        0.0;  !- Delta Temperature
      "
    idfObject = OpenStudio::IdfObject.load(zone_mixing_string)
    object = idfObject.get
    wsObject = workspace.addObject(object)
    new_zone_mixing_object = wsObject.get

    # echo the new zone mixing objects name back to the user, using the index based getString method
    runner.registerInfo("A zone mixing object named '#{new_zone_mixing_object.getString(0)}' was added.")

    # report final condition of model
    zone_mixing_objects = workspace.getObjectsByType('ZoneMixing'.to_IddObjectType)
    runner.registerFinalCondition("The building finished with #{zone_mixing_objects.size} zone mixing objects.")

    return true
  end
end

# register the measure to be used by the application
AddZoneMixingObject.new.registerWithApplication
