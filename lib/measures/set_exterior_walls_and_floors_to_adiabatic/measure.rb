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
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

# start the measure
class SetExteriorWallsAndFloorsToAdiabatic < OpenStudio::Measure::ModelMeasure
  # define the name that a user will see, this method may be deprecated as
  # the display name in PAT comes from the name field in measure.xml
  def name
    return "Set Exterior Walls and Floors to Adiabatic"
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for ext_roofs
    ext_roofs = OpenStudio::Measure::OSArgument.makeBoolArgument('ext_roofs', true)
    ext_roofs.setDisplayName('Make Exterior Roof Surfaces Adiabatic')
    ext_roofs.setDefaultValue(true)
    args << ext_roofs

    # make an argument for ext_floors
    ext_floors = OpenStudio::Measure::OSArgument.makeBoolArgument('ext_floors', true)
    ext_floors.setDisplayName('Make Exterior Exposed Floor Surfaces Adiabatic')
    ext_floors.setDefaultValue(true)
    args << ext_floors

    # make an argument for ground_floors
    ground_floors = OpenStudio::Measure::OSArgument.makeBoolArgument('ground_floors', true)
    ground_floors.setDisplayName('Make Ground Exposed Floor Surfaces Adiabatic')
    ground_floors.setDefaultValue(true)
    args << ground_floors

    # make an argument for north_walls
    north_walls = OpenStudio::Measure::OSArgument.makeBoolArgument('north_walls', true)
    north_walls.setDisplayName('Make North Facing Exterior Surfaces Adiabatic')
    north_walls.setDefaultValue(false)
    args << north_walls

    # make an argument for south_walls
    south_walls = OpenStudio::Measure::OSArgument.makeBoolArgument('south_walls', true)
    south_walls.setDisplayName('Make South Facing Exterior Surfaces Adiabatic')
    south_walls.setDefaultValue(false)
    args << south_walls

    # make an argument for east_walls
    east_walls = OpenStudio::Measure::OSArgument.makeBoolArgument('east_walls', true)
    east_walls.setDisplayName('Make East Facing Exterior Surfaces Adiabatic')
    east_walls.setDefaultValue(false)
    args << east_walls

    # make an argument for west_walls
    west_walls = OpenStudio::Measure::OSArgument.makeBoolArgument('west_walls', true)
    west_walls.setDisplayName('Make West Facing Exterior Surfaces Adiabatic')
    west_walls.setDefaultValue(false)
    args << west_walls

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
    ext_roofs = runner.getBoolArgumentValue('ext_roofs', user_arguments)
    ext_floors = runner.getBoolArgumentValue('ext_floors', user_arguments)
    ground_floors = runner.getBoolArgumentValue('ground_floors', user_arguments)
    north_walls = runner.getBoolArgumentValue('north_walls', user_arguments)
    south_walls = runner.getBoolArgumentValue('south_walls', user_arguments)
    east_walls = runner.getBoolArgumentValue('east_walls', user_arguments)
    west_walls = runner.getBoolArgumentValue('west_walls', user_arguments)

    # counter for number of constructions use for interior walls in initial construction
    orig_adiabatic = 0

    # make an array of walls that started as matched surfaces.
    # I need to do this first, because when one of pair changes to Adiabatic, the other will change to Outdoors
    surfaces_to_change = []
    surfaces = model.getSurfaces
    surfaces.each do |surface|
      if surface.outsideBoundaryCondition == 'Adiabatic'
        orig_adiabatic += 1
      end
      if ext_roofs && (surface.surfaceType == 'RoofCeiling') && (surface.outsideBoundaryCondition == 'Outdoors')
        surfaces_to_change << surface
      elsif ext_floors && (surface.surfaceType == 'Floor') && (surface.outsideBoundaryCondition == 'Outdoors')
        surfaces_to_change << surface
      elsif ground_floors && (surface.surfaceType == 'Floor') && (surface.outsideBoundaryCondition == 'Ground')
        surfaces_to_change << surface
      elsif (surface.surfaceType == 'Wall') && (surface.outsideBoundaryCondition == 'Outdoors') && (north_walls || south_walls || east_walls || west_walls)

        # get absolute azimuth and cardinal direction
        absoluteAzimuth = OpenStudio.convert(surface.azimuth, 'rad', 'deg').get + surface.space.get.directionofRelativeNorth + model.getBuilding.northAxis
        absoluteAzimuth -= 360.0 until absoluteAzimuth < 360.0
        if north_walls && ((absoluteAzimuth >= 315.0) || (absoluteAzimuth < 45.0))
          surfaces_to_change << surface
        elsif east_walls && ((absoluteAzimuth >= 45.0) && (absoluteAzimuth < 135.0))
          surfaces_to_change << surface
        elsif south_walls && ((absoluteAzimuth >= 135.0) && (absoluteAzimuth < 225.0))
          surfaces_to_change << surface
        elsif west_walls && ((absoluteAzimuth >= 225.0) && (absoluteAzimuth < 315.0))
          surfaces_to_change << surface
        end
      end
    end

    # change boundary condition and assign constructions
    surfaces_to_change.each do |surface|
      if surface.construction.is_initialized
        surface.setConstruction(surface.construction.get)
      end
      # this will remove any existing sub-surfaces for the surface.
      surface.setOutsideBoundaryCondition('Adiabatic')
    end

    # reporting initial condition of model
    runner.registerInitialCondition("The initial model has #{orig_adiabatic} adiabatic surfaces.")

    # reporting final condition of model
    runner.registerFinalCondition("The final model has #{orig_adiabatic + surfaces_to_change.size} adiabatic surfaces.")

    return true
  end
end

# this allows the measure to be use by the application
SetExteriorWallsAndFloorsToAdiabatic.new.registerWithApplication
