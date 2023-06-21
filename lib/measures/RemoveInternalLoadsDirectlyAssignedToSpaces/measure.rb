# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class RemoveInternalLoadsDirectlyAssignedToSpaces < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return 'RemoveInternalLoadsDirectlyAssignedToSpaces'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables

    # reporting initial condition of model
    spaceLoads = model.getSpaceLoadInstances
    runner.registerInitialCondition("The building started with #{spaceLoads.size} space load instances.")

    # loop through spaces remove space loads
    spaces = model.getSpaces
    spaces.each do |space|
      # removing or detaching loads directly assigned to space objects.
      space.internalMass.each(&:remove)
      space.people.each(&:remove)
      space.lights.each(&:remove)
      space.luminaires.each(&:remove)
      space.electricEquipment.each(&:remove)
      space.gasEquipment.each(&:remove)
      space.hotWaterEquipment.each(&:remove)
      space.steamEquipment.each(&:remove)
      space.otherEquipment.each(&:remove)
      space.spaceInfiltrationDesignFlowRates.each(&:remove)
      space.spaceInfiltrationEffectiveLeakageAreas.each(&:remove)

      space.resetDesignSpecificationOutdoorAir
    end

    # reporting final condition of model
    spaceLoads = model.getSpaceLoadInstances
    runner.registerFinalCondition("The building finished with #{spaceLoads.size} space load instances.")

    return true
  end
end

# this allows the measure to be use by the application
RemoveInternalLoadsDirectlyAssignedToSpaces.new.registerWithApplication
